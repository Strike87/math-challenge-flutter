import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'p1_f01_integrity_store.dart';

const bool _p1F01DeviceValidationEnabled = bool.fromEnvironment(
  'P1_F01_DEVICE_VALIDATION',
  defaultValue: false,
);

@immutable
final class P1F01DeviceValidationSnapshot {
  const P1F01DeviceValidationSnapshot({
    required this.integrityVersion,
    required this.localWindowSequence,
    required this.status,
    required this.admittedORawCount,
    required this.lastAdmittedOpportunityOrdinal,
    required this.lastLegalSetCode,
    required this.lastReconciledOrdinal,
    required this.hasIntegrityDefect,
    required this.hasCleanClosureSignal,
    required this.legalSetCounters,
  });

  factory P1F01DeviceValidationSnapshot.fromStore(
    P1F01IntegritySnapshot snapshot,
  ) {
    return P1F01DeviceValidationSnapshot(
      integrityVersion: snapshot.integrityVersion,
      localWindowSequence: snapshot.localWindowSequence,
      status: snapshot.status,
      admittedORawCount: snapshot.admittedORawCount,
      lastAdmittedOpportunityOrdinal: snapshot.lastAdmittedOpportunityOrdinal,
      lastLegalSetCode: snapshot.lastLegalSetCode,
      lastReconciledOrdinal: snapshot.lastReconciledOrdinal,
      hasIntegrityDefect: snapshot.hasIntegrityDefect,
      hasCleanClosureSignal: snapshot.hasCleanClosureSignal,
      legalSetCounters: Map.unmodifiable(snapshot.legalSetCounters),
    );
  }

  final int integrityVersion;
  final int localWindowSequence;
  final P1F01IntegrityWindowStatus status;
  final int admittedORawCount;
  final int? lastAdmittedOpportunityOrdinal;
  final String? lastLegalSetCode;
  final int? lastReconciledOrdinal;
  final bool hasIntegrityDefect;
  final bool hasCleanClosureSignal;
  final Map<String, int> legalSetCounters;

  Map<String, Object?> toJson() => {
        'integrityVersion': integrityVersion,
        'localWindowSequence': localWindowSequence,
        'status': status.storageValue,
        'admittedORawCount': admittedORawCount,
        'lastAdmittedOrdinal': lastAdmittedOpportunityOrdinal,
        'lastLegalSetCode': lastLegalSetCode,
        'lastReconciledOrdinal': lastReconciledOrdinal,
        'hasIntegrityDefect': hasIntegrityDefect,
        'hasCleanClosureSignal': hasCleanClosureSignal,
        'legalSetCounters': legalSetCounters,
      };
}

final class P1F01DeviceValidationProbe {
  P1F01DeviceValidationProbe(this._store);

  final P1F01IntegrityStore _store;

  static bool availableFor({
    required bool isDebugBuild,
    required bool validationFlag,
  }) =>
      isDebugBuild && validationFlag;

  bool get isAvailable => availableFor(
        isDebugBuild: kDebugMode,
        validationFlag: _p1F01DeviceValidationEnabled,
      );

  Future<P1F01DeviceValidationSnapshot?> currentSnapshot() async {
    if (!isAvailable) return null;
    return _sanitize(await _store.latestSnapshot());
  }

  Future<List<P1F01DeviceValidationSnapshot>> retainedSnapshots() async {
    if (!isAvailable) return const [];
    final snapshots = await _store.retainedSnapshots();
    return List.unmodifiable(snapshots.map(_sanitizeOrThrow));
  }

  Future<void> drain() async {
    if (!isAvailable) return;
    await _store.drain();
  }

  Future<P1F01OpportunityAdmissionResult?> retryLastAdmission() async {
    if (!isAvailable) return null;
    final snapshot = await _store.latestSnapshot();
    final ordinal = snapshot?.lastAdmittedOpportunityOrdinal;
    final code = snapshot?.lastLegalSetCode;
    if (ordinal == null || code == null) {
      return P1F01OpportunityAdmissionResult.failedClosed;
    }
    final legalSetCode = P1F01LegalSetCode.fromStoredValue(code);
    if (legalSetCode == null) {
      return P1F01OpportunityAdmissionResult.failedClosed;
    }
    return _store.admitOpportunity(
      opportunityOrdinalWithinRun: ordinal,
      legalSetCode: legalSetCode,
    );
  }

  Future<P1F01OpportunityAdmissionResult?>
      retryConflictingLastAdmission() async {
    if (!isAvailable) return null;
    final snapshot = await _store.latestSnapshot();
    final ordinal = snapshot?.lastAdmittedOpportunityOrdinal;
    final code = snapshot?.lastLegalSetCode;
    if (ordinal == null || code == null) {
      return P1F01OpportunityAdmissionResult.failedClosed;
    }
    final legalSetCode = P1F01LegalSetCode.fromStoredValue(code);
    if (legalSetCode == null) {
      return P1F01OpportunityAdmissionResult.failedClosed;
    }
    return _store.admitOpportunity(
      opportunityOrdinalWithinRun: ordinal,
      legalSetCode: legalSetCode == P1F01LegalSetCode.unknown
          ? P1F01LegalSetCode.allPhase1
          : P1F01LegalSetCode.unknown,
    );
  }

  Future<P1F01OpportunityAdmissionResult?> admitGappedOrdinal() async {
    if (!isAvailable) return null;
    final snapshot = await _store.latestSnapshot();
    final lastOrdinal = snapshot?.lastAdmittedOpportunityOrdinal ?? 0;
    final code = snapshot?.lastLegalSetCode;
    final legalSetCode = code == null
        ? P1F01LegalSetCode.unknown
        : P1F01LegalSetCode.fromStoredValue(code);
    if (legalSetCode == null) {
      return P1F01OpportunityAdmissionResult.failedClosed;
    }
    return _store.admitOpportunity(
      opportunityOrdinalWithinRun: lastOrdinal + 2,
      legalSetCode: legalSetCode,
    );
  }

  Future<bool?> armBeforeCommit() async {
    if (!isAvailable) return null;
    return _store.boundaryController.armBeforeCommit();
  }

  Future<bool?> armAfterCommitBeforeAck() async {
    if (!isAvailable) return null;
    return _store.boundaryController.armAfterCommitBeforeAck();
  }

  Future<String?> boundaryState() async {
    if (!isAvailable) return null;
    return _store.boundaryController.state.value;
  }

  Future<bool?> releaseBoundary() async {
    if (!isAvailable) return null;
    return _store.boundaryController.releaseBoundary();
  }

  Future<Map<String, Object?>> handleCommand(String? command) async {
    if (!isAvailable) return const {'status': 'unavailable'};
    switch (command) {
      case 'readCurrent':
        return {'snapshot': (await currentSnapshot())?.toJson()};
      case 'readRetained':
        return {
          'snapshots': [
            for (final snapshot in await retainedSnapshots()) snapshot.toJson(),
          ],
        };
      case 'drain':
        await drain();
        return const {'status': 'drained'};
      case 'retryExact':
        return {'result': (await retryLastAdmission())?.name};
      case 'retryConflict':
        return {'result': (await retryConflictingLastAdmission())?.name};
      case 'retryGap':
        return {'result': (await admitGappedOrdinal())?.name};
      case 'armBeforeCommit':
        return {'armed': await armBeforeCommit()};
      case 'armAfterCommitBeforeAck':
        return {'armed': await armAfterCommitBeforeAck()};
      case 'readBoundaryState':
        return {'state': await boundaryState()};
      case 'releaseBoundary':
        return {'released': await releaseBoundary()};
      default:
        return const {'status': 'unsupported_command'};
    }
  }

  P1F01DeviceValidationSnapshot? _sanitize(
    P1F01IntegritySnapshot? snapshot,
  ) {
    if (snapshot == null) return null;
    return P1F01DeviceValidationSnapshot.fromStore(snapshot);
  }

  P1F01DeviceValidationSnapshot _sanitizeOrThrow(
    P1F01IntegritySnapshot snapshot,
  ) =>
      P1F01DeviceValidationSnapshot.fromStore(snapshot);
}

final class P1F01DeviceValidationServiceExtension {
  static const name = 'ext.mathChallenge.p1F01Integrity';
  static bool _registered = false;
  static P1F01DeviceValidationProbe? _activeProbe;

  static bool shouldRegisterFor({
    required bool isDebugBuild,
    required bool validationFlag,
  }) =>
      P1F01DeviceValidationProbe.availableFor(
        isDebugBuild: isDebugBuild,
        validationFlag: validationFlag,
      );

  static void register(P1F01DeviceValidationProbe probe) {
    if (!probe.isAvailable) return;
    _activeProbe = probe;
    if (_registered) return;
    developer.registerExtension(name, (method, parameters) async {
      final payload =
          await _activeProbe?.handleCommand(parameters['command']) ??
              const {'status': 'unavailable'};
      return developer.ServiceExtensionResponse.result(jsonEncode(payload));
    });
    _registered = true;
  }
}
