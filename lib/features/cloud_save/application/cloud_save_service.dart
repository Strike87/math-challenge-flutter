import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../../engine/game_state.dart';
import '../data/play_games_saved_games_transport.dart';
import '../domain/cloud_progress_document.dart';
import '../domain/cloud_progress_policy.dart';

typedef CloudUtcMilliseconds = int Function();
typedef CloudRevisionIdGenerator = String Function();

enum CloudSyncChoice {
  keepThisDevice,
  useCloud,
  primaryCloud,
  conflictingCloud,
}

sealed class CloudSyncResult {
  const CloudSyncResult();
}

final class CloudSyncNoChange extends CloudSyncResult {
  const CloudSyncNoChange();
}

final class CloudSyncUploaded extends CloudSyncResult {
  const CloudSyncUploaded();
}

final class CloudSyncRestoredFromCloud extends CloudSyncResult {
  const CloudSyncRestoredFromCloud();
}

final class CloudSyncAutomaticallyMerged extends CloudSyncResult {
  const CloudSyncAutomaticallyMerged();
}

final class CloudSyncUserChoiceMerged extends CloudSyncResult {
  const CloudSyncUserChoiceMerged();
}

final class CloudSyncNativeConflictResolvedResyncRequired
    extends CloudSyncResult {
  const CloudSyncNativeConflictResolvedResyncRequired();
}

sealed class CloudSyncNeedsUserChoice extends CloudSyncResult {
  const CloudSyncNeedsUserChoice();
}

final class CloudSyncDeviceCloudChoice extends CloudSyncNeedsUserChoice {
  const CloudSyncDeviceCloudChoice._({
    required this.keepThisDeviceCandidate,
    required this.useCloudCandidate,
    required this.mergePlan,
    required this.resetGeneration,
    required _LocalBasis basis,
  }) : _basis = basis;

  final CloudProgress keepThisDeviceCandidate;
  final CloudProgress useCloudCandidate;
  final CloudProgressMergePlan mergePlan;
  final int resetGeneration;
  final _LocalBasis _basis;
}

final class CloudSyncNativeCloudChoice extends CloudSyncNeedsUserChoice {
  const CloudSyncNativeCloudChoice._({
    required this.primaryCloudCandidate,
    required this.conflictingCloudCandidate,
    required this.mergePlan,
    required this.resetGeneration,
    required String handle,
  }) : _handle = handle;

  final CloudProgress primaryCloudCandidate;
  final CloudProgress conflictingCloudCandidate;
  final CloudProgressMergePlan mergePlan;
  final int resetGeneration;
  final String _handle;
}

final class CloudSyncNotAuthenticated extends CloudSyncResult {
  const CloudSyncNotAuthenticated();
}

final class CloudSyncMalformedCloudDocument extends CloudSyncResult {
  const CloudSyncMalformedCloudDocument([this.diagnostic]);

  final String? diagnostic;
}

final class CloudSyncUnsupportedSchema extends CloudSyncResult {
  const CloudSyncUnsupportedSchema();
}

final class CloudSyncInvalidLineage extends CloudSyncResult {
  const CloudSyncInvalidLineage();
}

final class CloudSyncUnknownLocalRevision extends CloudSyncResult {
  const CloudSyncUnknownLocalRevision();
}

final class CloudSyncInvalidLocalMetadata extends CloudSyncResult {
  const CloudSyncInvalidLocalMetadata();
}

final class CloudSyncTransportFailure extends CloudSyncResult {
  const CloudSyncTransportFailure(this.error, [this.diagnostic]);

  final SavedGamesTransportError error;
  final String? diagnostic;
}

final class CloudSyncStaleConflict extends CloudSyncResult {
  const CloudSyncStaleConflict([this.diagnostic]);

  final String? diagnostic;
}

final class CloudSyncRepeatedConflict extends CloudSyncResult {
  const CloudSyncRepeatedConflict();
}

final class CloudSyncChangedLocalState extends CloudSyncResult {
  const CloudSyncChangedLocalState();
}

final class CloudSyncLocalPersistenceFailure extends CloudSyncResult {
  const CloudSyncLocalPersistenceFailure();
}

class CloudSaveService {
  CloudSaveService({
    required GameState state,
    required SavedGamesTransport transport,
    CloudProgressPolicy policy = const CloudProgressPolicy(),
    CloudUtcMilliseconds? utcMilliseconds,
    CloudRevisionIdGenerator? revisionIdGenerator,
  })  : _state = state,
        _transport = transport,
        _policy = policy,
        _utcMilliseconds = utcMilliseconds ??
            (() => DateTime.now().toUtc().millisecondsSinceEpoch),
        _revisionIdGenerator = revisionIdGenerator ?? _secureRevisionId;

  final GameState _state;
  final SavedGamesTransport _transport;
  final CloudProgressPolicy _policy;
  final CloudUtcMilliseconds _utcMilliseconds;
  final CloudRevisionIdGenerator _revisionIdGenerator;

  Future<CloudSyncResult> sync() async {
    final basis = _LocalBasis.capture(_state);
    if (!basis.hasValidMetadata) {
      return const CloudSyncInvalidLocalMetadata();
    }

    final opened = await _transport.open();
    if (opened is SavedGamesTransportFailure) {
      return _openFailure(opened);
    }
    if (opened is SavedGamesOpenedEmpty) {
      return _syncEmpty(basis);
    }
    if (opened is SavedGamesOpenedData) {
      final decoded = _decode(opened.bytes);
      if (decoded.failure != null) return decoded.failure!;
      return _syncDocument(basis, decoded.document!);
    }
    if (opened is SavedGamesConflict) {
      return _syncNativeConflict(opened);
    }
    return const CloudSyncTransportFailure(
      SavedGamesTransportError.invalidNativeResult,
    );
  }

  Future<CloudSyncResult> resolveUserChoice(
    CloudSyncNeedsUserChoice pending,
    CloudSyncChoice choice,
  ) {
    if (pending is CloudSyncDeviceCloudChoice) {
      return _resolveDeviceCloudChoice(pending, choice);
    }
    if (pending is CloudSyncNativeCloudChoice) {
      return _resolveNativeCloudChoice(pending, choice);
    }
    throw ArgumentError.value(pending, 'pending');
  }

  Future<CloudSyncResult> _syncEmpty(_LocalBasis basis) async {
    if (basis.hasUnknownRevision) {
      return const CloudSyncUnknownLocalRevision();
    }
    if (basis.isFresh) return const CloudSyncNoChange();
    if (!basis.matches(_state)) return const CloudSyncChangedLocalState();
    return _commitAndAccept(_root(basis), basis, importProgress: false);
  }

  Future<CloudSyncResult> _syncDocument(
    _LocalBasis basis,
    CloudProgressDocument cloud,
  ) async {
    if (basis.hasUnknownRevision && basis.revisionId != cloud.revisionId) {
      return const CloudSyncUnknownLocalRevision();
    }
    if (basis.isFresh) {
      return _accept(
        cloud,
        basis,
        importProgress: true,
        success: const CloudSyncRestoredFromCloud(),
      );
    }

    final local = _localDocument(basis, cloud);
    if (local == null) return const CloudSyncInvalidLocalMetadata();
    final decision = _policy.decide(
      local,
      cloud,
      lastSyncedRevisionId: basis.lastSyncedRevisionId,
    );
    switch (decision.kind) {
      case CloudProgressDecisionKind.noChange:
        return _accept(
          cloud,
          basis,
          importProgress: false,
          success: const CloudSyncNoChange(),
        );
      case CloudProgressDecisionKind.useCloud:
        return _accept(
          cloud,
          basis,
          importProgress: true,
          success: const CloudSyncRestoredFromCloud(),
        );
      case CloudProgressDecisionKind.useLocal:
        return _commitAndAccept(local, basis, importProgress: false);
      case CloudProgressDecisionKind.mergeRequired:
        return _commitAndAccept(
          _mergeDocument(
            decision.mergedCandidate!,
            decision.mergePlan!,
            local.resetGeneration,
          ),
          basis,
          importProgress: true,
          success: const CloudSyncAutomaticallyMerged(),
        );
      case CloudProgressDecisionKind.needsUserChoice:
        return CloudSyncDeviceCloudChoice._(
          keepThisDeviceCandidate: decision.keepLocalCandidate!,
          useCloudCandidate: decision.useCloudCandidate!,
          mergePlan: decision.mergePlan!,
          resetGeneration: local.resetGeneration,
          basis: basis,
        );
      case CloudProgressDecisionKind.invalidLineage:
        return const CloudSyncInvalidLineage();
    }
  }

  Future<CloudSyncResult> _syncNativeConflict(
    SavedGamesConflict conflict,
  ) async {
    final primary = _decode(conflict.snapshotBytes);
    if (primary.failure != null) return primary.failure!;
    final other = _decode(conflict.conflictingSnapshotBytes);
    if (other.failure != null) return other.failure!;
    final primaryDocument = primary.document!;
    final otherDocument = other.document!;
    final decision = _policy.decide(primaryDocument, otherDocument);
    switch (decision.kind) {
      case CloudProgressDecisionKind.noChange:
      case CloudProgressDecisionKind.useLocal:
        return _resolveNative(conflict.handle, conflict.snapshotBytes);
      case CloudProgressDecisionKind.useCloud:
        return _resolveNative(
          conflict.handle,
          conflict.conflictingSnapshotBytes,
        );
      case CloudProgressDecisionKind.mergeRequired:
        return _resolveNative(
          conflict.handle,
          _bytes(_mergeDocument(
            decision.mergedCandidate!,
            decision.mergePlan!,
            primaryDocument.resetGeneration,
          )),
        );
      case CloudProgressDecisionKind.needsUserChoice:
        return CloudSyncNativeCloudChoice._(
          primaryCloudCandidate: decision.keepLocalCandidate!,
          conflictingCloudCandidate: decision.useCloudCandidate!,
          mergePlan: decision.mergePlan!,
          resetGeneration: primaryDocument.resetGeneration,
          handle: conflict.handle,
        );
      case CloudProgressDecisionKind.invalidLineage:
        return const CloudSyncInvalidLineage();
    }
  }

  Future<CloudSyncResult> _resolveDeviceCloudChoice(
    CloudSyncDeviceCloudChoice pending,
    CloudSyncChoice choice,
  ) async {
    if (choice != CloudSyncChoice.keepThisDevice &&
        choice != CloudSyncChoice.useCloud) {
      throw ArgumentError.value(choice, 'choice');
    }
    if (!pending._basis.matches(_state)) {
      return const CloudSyncChangedLocalState();
    }
    final progress = choice == CloudSyncChoice.keepThisDevice
        ? pending.keepThisDeviceCandidate
        : pending.useCloudCandidate;
    return _commitAndAccept(
      _mergeDocument(
        progress,
        pending.mergePlan,
        pending.resetGeneration,
      ),
      pending._basis,
      importProgress: true,
      success: const CloudSyncUserChoiceMerged(),
    );
  }

  Future<CloudSyncResult> _resolveNativeCloudChoice(
    CloudSyncNativeCloudChoice pending,
    CloudSyncChoice choice,
  ) {
    if (choice != CloudSyncChoice.primaryCloud &&
        choice != CloudSyncChoice.conflictingCloud) {
      throw ArgumentError.value(choice, 'choice');
    }
    final progress = choice == CloudSyncChoice.primaryCloud
        ? pending.primaryCloudCandidate
        : pending.conflictingCloudCandidate;
    return _resolveNative(
      pending._handle,
      _bytes(_mergeDocument(
        progress,
        pending.mergePlan,
        pending.resetGeneration,
      )),
    );
  }

  Future<CloudSyncResult> _commitAndAccept(
    CloudProgressDocument document,
    _LocalBasis basis, {
    required bool importProgress,
    CloudSyncResult success = const CloudSyncUploaded(),
  }) async {
    if (!basis.matches(_state)) return const CloudSyncChangedLocalState();
    final committed = await _transport.commit(_bytes(document));
    if (committed is SavedGamesConflict) {
      return const CloudSyncRepeatedConflict();
    }
    if (committed is SavedGamesTransportFailure) {
      return _transportFailure(committed);
    }
    if (committed is! SavedGamesCommitted) {
      return const CloudSyncTransportFailure(
        SavedGamesTransportError.invalidNativeResult,
      );
    }
    if (!basis.matches(_state)) return const CloudSyncChangedLocalState();
    return _accept(
      document,
      basis,
      importProgress: importProgress,
      success: success,
    );
  }

  Future<CloudSyncResult> _accept(
    CloudProgressDocument document,
    _LocalBasis basis, {
    required bool importProgress,
    required CloudSyncResult success,
  }) async {
    if (!basis.matches(_state)) return const CloudSyncChangedLocalState();
    return await _state.acceptCloudProgressDocument(
      document,
      importProgress: importProgress,
    )
        ? success
        : const CloudSyncLocalPersistenceFailure();
  }

  Future<CloudSyncResult> _resolveNative(
    String handle,
    Uint8List bytes,
  ) async {
    final resolved = await _transport.resolve(handle, bytes);
    if (resolved is SavedGamesConflict) {
      return const CloudSyncRepeatedConflict();
    }
    if (resolved is SavedGamesTransportFailure) {
      return resolved.error == SavedGamesTransportError.staleConflictHandle
          ? CloudSyncStaleConflict(resolved.diagnostic)
          : _transportFailure(resolved);
    }
    return resolved is SavedGamesResolved
        ? const CloudSyncNativeConflictResolvedResyncRequired()
        : const CloudSyncTransportFailure(
            SavedGamesTransportError.invalidNativeResult,
          );
  }

  CloudProgressDocument? _localDocument(
    _LocalBasis basis,
    CloudProgressDocument cloud,
  ) {
    try {
      if (basis.revisionId == null) return _root(basis);
      final recoveredRevision = basis.revision ??
          (cloud.revisionId == basis.revisionId ? cloud.revision : null);
      if (recoveredRevision == null) return null;
      if (basis.dirty) {
        return CloudProgressDocument(
          revision: recoveredRevision + 1,
          revisionId: _revisionIdGenerator(),
          parentRevisionId: basis.revisionId,
          resetGeneration: basis.resetGeneration,
          updatedAtUtcMs: _utcMilliseconds(),
          progress: basis.progress,
        );
      }
      return CloudProgressDocument(
        revision: recoveredRevision,
        revisionId: basis.revisionId!,
        parentRevisionId: basis.parentRevisionId,
        mergeParentRevisionIds: basis.mergeParentRevisionIds,
        resetGeneration: basis.resetGeneration,
        updatedAtUtcMs: 0,
        progress: basis.progress,
      );
    } on ArgumentError {
      return null;
    }
  }

  CloudProgressDocument _root(_LocalBasis basis) => CloudProgressDocument(
        revision: 0,
        revisionId: _revisionIdGenerator(),
        resetGeneration: basis.resetGeneration,
        updatedAtUtcMs: _utcMilliseconds(),
        progress: basis.progress,
      );

  CloudProgressDocument _mergeDocument(
    CloudProgress progress,
    CloudProgressMergePlan plan,
    int resetGeneration,
  ) =>
      CloudProgressDocument(
        revision: plan.revision,
        revisionId: _revisionIdGenerator(),
        mergeParentRevisionIds: plan.parentRevisionIds,
        resetGeneration: resetGeneration,
        updatedAtUtcMs: _utcMilliseconds(),
        progress: progress,
      );

  _DecodedDocument _decode(Uint8List bytes) {
    try {
      final parsed = CloudProgressDocument.decode(utf8.decode(bytes));
      if (parsed.document != null) {
        return _DecodedDocument.success(parsed.document!);
      }
      return parsed.error == 'unsupported future schema' ||
              parsed.error == 'unsupported schema'
          ? const _DecodedDocument.failure(CloudSyncUnsupportedSchema())
          : _DecodedDocument.failure(
              CloudSyncMalformedCloudDocument(parsed.error),
            );
    } on FormatException catch (error) {
      return _DecodedDocument.failure(
        CloudSyncMalformedCloudDocument(error.message),
      );
    }
  }

  CloudSyncResult _openFailure(SavedGamesTransportFailure failure) =>
      failure.error == SavedGamesTransportError.notAuthenticated
          ? const CloudSyncNotAuthenticated()
          : _transportFailure(failure);

  CloudSyncTransportFailure _transportFailure(
    SavedGamesTransportFailure failure,
  ) =>
      CloudSyncTransportFailure(failure.error, failure.diagnostic);

  Uint8List _bytes(CloudProgressDocument document) =>
      Uint8List.fromList(utf8.encode(document.encode()));

  static String _secureRevisionId() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}

final class _DecodedDocument {
  const _DecodedDocument.success(this.document) : failure = null;
  const _DecodedDocument.failure(this.failure) : document = null;

  final CloudProgressDocument? document;
  final CloudSyncResult? failure;
}

final class _LocalBasis {
  const _LocalBasis({
    required this.progress,
    required this.resetGeneration,
    required this.revision,
    required this.revisionId,
    required this.parentRevisionId,
    required this.mergeParentRevisionIds,
    required this.lastSyncedRevisionId,
    required this.dirty,
  });

  factory _LocalBasis.capture(GameState state) => _LocalBasis(
        progress: state.exportCloudProgress(),
        resetGeneration: state.cloudResetGeneration,
        revision: state.cloudRevision,
        revisionId: state.cloudRevisionId,
        parentRevisionId: state.cloudParentRevisionId,
        mergeParentRevisionIds: state.cloudMergeParentRevisionIds,
        lastSyncedRevisionId: state.cloudLastSyncedRevisionId,
        dirty: state.cloudDirty,
      );

  final CloudProgress progress;
  final int resetGeneration;
  final int? revision;
  final String? revisionId;
  final String? parentRevisionId;
  final List<String> mergeParentRevisionIds;
  final String? lastSyncedRevisionId;
  final bool dirty;

  bool get hasUnknownRevision => revisionId != null && revision == null;

  bool get hasValidMetadata {
    if (resetGeneration < 0 || (revision != null && revision! < 0))
      return false;
    if (revisionId == null) {
      return revision == null &&
          parentRevisionId == null &&
          mergeParentRevisionIds.isEmpty;
    }
    return parentRevisionId == null
        ? mergeParentRevisionIds.isEmpty ||
            (mergeParentRevisionIds.length == 2 &&
                mergeParentRevisionIds.toSet().length == 2)
        : mergeParentRevisionIds.isEmpty;
  }

  bool get isFresh =>
      progress == CloudProgress.empty() &&
      resetGeneration == 0 &&
      revision == null &&
      revisionId == null &&
      !dirty;

  bool matches(GameState state) => _sameAs(_LocalBasis.capture(state));

  bool _sameAs(_LocalBasis other) =>
      progress == other.progress &&
      resetGeneration == other.resetGeneration &&
      revision == other.revision &&
      revisionId == other.revisionId &&
      parentRevisionId == other.parentRevisionId &&
      _sameStrings(mergeParentRevisionIds, other.mergeParentRevisionIds) &&
      lastSyncedRevisionId == other.lastSyncedRevisionId &&
      dirty == other.dirty;

  bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
