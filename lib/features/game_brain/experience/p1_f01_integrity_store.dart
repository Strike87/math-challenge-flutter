import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../models/enums.dart';
import '../../gameplay/domain/question_difficulty_legality.dart';

enum P1F01IntegrityWindowStatus {
  open('OPEN'),
  cleanlyClosed('CLEANLY_CLOSED'),
  leftUnclean('LEFT_UNCLEAN');

  const P1F01IntegrityWindowStatus(this.storageValue);

  final String storageValue;

  static P1F01IntegrityWindowStatus fromStorage(String value) =>
      P1F01IntegrityWindowStatus.values.firstWhere(
        (status) => status.storageValue == value,
      );
}

enum P1F01IntegrityOperation {
  recoverOpenWindows,
  admitWindow,
  admitOpportunity,
  reconcileTerminal,
  closeClean,
  markLeftUnclean,
  deleteAll,
}

enum P1F01OpportunityAdmissionResult {
  admitted,
  alreadyAdmitted,
  failedClosed,
}

enum P1F01TransactionBoundaryState {
  disarmed('DISARMED'),
  armBeforeCommit('ARM_BEFORE_COMMIT'),
  reachedBeforeCommit('REACHED_BEFORE_COMMIT'),
  armAfterCommitBeforeAck('ARM_AFTER_COMMIT_BEFORE_ACK'),
  reachedAfterCommitBeforeAck('REACHED_AFTER_COMMIT_BEFORE_ACK');

  const P1F01TransactionBoundaryState(this.value);

  final String value;
}

/// Debug-only, in-memory control for physical transaction-boundary validation.
final class P1F01TransactionBoundaryController {
  static const bool _validationEnabled = bool.fromEnvironment(
    'P1_F01_DEVICE_VALIDATION',
    defaultValue: false,
  );

  P1F01TransactionBoundaryState _state = P1F01TransactionBoundaryState.disarmed;
  P1F01TransactionBoundaryState? _armedState;
  Completer<void>? _release;

  static bool availableFor({
    required bool isDebugBuild,
    required bool validationFlag,
  }) =>
      isDebugBuild && validationFlag;

  bool get isAvailable => availableFor(
        isDebugBuild: kDebugMode,
        validationFlag: _validationEnabled,
      );

  P1F01TransactionBoundaryState get state => _state;

  bool armBeforeCommit() => _arm(
        P1F01TransactionBoundaryState.armBeforeCommit,
      );

  bool armAfterCommitBeforeAck() => _arm(
        P1F01TransactionBoundaryState.armAfterCommitBeforeAck,
      );

  bool releaseBoundary() {
    final release = _release;
    if (release == null || release.isCompleted) return false;
    release.complete();
    return true;
  }

  Future<void> reachedBeforeCommit() => _reach(
        P1F01TransactionBoundaryState.armBeforeCommit,
        P1F01TransactionBoundaryState.reachedBeforeCommit,
      );

  Future<void> reachedAfterCommitBeforeAck() => _reach(
        P1F01TransactionBoundaryState.armAfterCommitBeforeAck,
        P1F01TransactionBoundaryState.reachedAfterCommitBeforeAck,
      );

  bool _arm(P1F01TransactionBoundaryState armState) {
    if (!isAvailable || _state != P1F01TransactionBoundaryState.disarmed) {
      return false;
    }
    _armedState = armState;
    _state = armState;
    return true;
  }

  Future<void> _reach(
    P1F01TransactionBoundaryState armState,
    P1F01TransactionBoundaryState reachedState,
  ) async {
    if (!isAvailable || _armedState != armState) return;
    _armedState = null;
    _state = reachedState;
    final release = _release = Completer<void>();
    await release.future;
    if (identical(_release, release)) {
      _release = null;
      _state = P1F01TransactionBoundaryState.disarmed;
    }
  }
}

@immutable
final class P1F01LegalSetCode {
  const P1F01LegalSetCode._(this.value);

  static const unknown = P1F01LegalSetCode._('V1_UNKNOWN');
  static const allPhase1 = P1F01LegalSetCode._('V1_EMH_MASK_7');
  static const _phase1 = <Difficulty, int>{
    Difficulty.easy: 1,
    Difficulty.medium: 2,
    Difficulty.hard: 4,
  };

  final String value;

  static P1F01LegalSetCode? fromStoredValue(String value) {
    if (value == unknown.value ||
        RegExp(r'^V1_EMH_MASK_[1-7]$').hasMatch(value)) {
      return P1F01LegalSetCode._(value);
    }
    return null;
  }

  static P1F01LegalSetCode fromLegality(
    QuestionDifficultyLegality? legality,
  ) {
    if (legality == null || legality.legalDifficulties.isEmpty) {
      return unknown;
    }
    var mask = 0;
    for (final difficulty in legality.legalDifficulties) {
      final bit = _phase1[difficulty];
      if (bit == null) return unknown;
      mask |= bit;
    }
    return P1F01LegalSetCode._('V1_EMH_MASK_$mask');
  }

  @override
  bool operator ==(Object other) =>
      other is P1F01LegalSetCode && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

@immutable
final class P1F01IntegritySnapshot {
  const P1F01IntegritySnapshot({
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
}

final class P1F01IntegrityStore {
  P1F01IntegrityStore({
    DatabaseFactory? databaseFactory,
    String? databasePath,
    this.failureHook,
    P1F01TransactionBoundaryController? boundaryController,
  })  : _databaseFactory = databaseFactory,
        _databasePath = databasePath,
        _boundaryController =
            boundaryController ?? P1F01TransactionBoundaryController();

  static const int integrityVersion = 1;
  static const int _maxWindowRows = 8;
  static const String _windowTable = 'p1_f01_integrity_window';
  static const String _counterTable = 'p1_f01_integrity_legal_set_count';

  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;
  final void Function(P1F01IntegrityOperation operation)? failureHook;
  final P1F01TransactionBoundaryController _boundaryController;
  Future<void> _queue = Future<void>.value();
  Database? _database;

  P1F01TransactionBoundaryController get boundaryController =>
      _boundaryController;

  Future<P1F01IntegritySnapshot?> recoverOpenWindows() =>
      _guarded<P1F01IntegritySnapshot?>(
        P1F01IntegrityOperation.recoverOpenWindows,
        () => _serialize(() async {
          final db = await _db();
          await db.transaction((txn) async {
            _fail(P1F01IntegrityOperation.recoverOpenWindows);
            await txn.update(
              _windowTable,
              {'status': P1F01IntegrityWindowStatus.leftUnclean.storageValue},
              where: 'status = ?',
              whereArgs: [P1F01IntegrityWindowStatus.open.storageValue],
            );
          });
          return await _latestSnapshot();
        }),
      );

  Future<P1F01IntegritySnapshot?> admitWindow() =>
      _guarded<P1F01IntegritySnapshot?>(
        P1F01IntegrityOperation.admitWindow,
        () => _serialize(() async {
          final db = await _db();
          late final int sequence;
          await db.transaction((txn) async {
            _fail(P1F01IntegrityOperation.admitWindow);
            await txn.update(
              _windowTable,
              {'status': P1F01IntegrityWindowStatus.leftUnclean.storageValue},
              where: 'status = ?',
              whereArgs: [P1F01IntegrityWindowStatus.open.storageValue],
            );
            sequence = await txn.insert(_windowTable, {
              'integrity_version': integrityVersion,
              'status': P1F01IntegrityWindowStatus.open.storageValue,
              'admitted_o_raw_count': 0,
              'known_integrity_defect': 0,
              'clean_closure_signal': 0,
            });
            await _pruneOldWindows(txn, sequence);
          });
          return await _snapshot(sequence);
        }),
      );

  Future<P1F01OpportunityAdmissionResult> admitOpportunity({
    required int opportunityOrdinalWithinRun,
    required P1F01LegalSetCode legalSetCode,
  }) async {
    final result = await _guarded(
      P1F01IntegrityOperation.admitOpportunity,
      () => _serialize(() async {
        final db = await _db();
        final result = await db.transaction((txn) async {
          _fail(P1F01IntegrityOperation.admitOpportunity);
          final window = await _latestOpenWindow(txn);
          if (window == null) {
            return P1F01OpportunityAdmissionResult.failedClosed;
          }
          final sequence = window['local_window_sequence'] as int;
          final lastOrdinal =
              window['last_admitted_opportunity_ordinal'] as int?;
          final lastCode = window['last_legal_set_code'] as String?;
          final expected = (lastOrdinal ?? 0) + 1;

          if (lastOrdinal == opportunityOrdinalWithinRun &&
              lastCode == legalSetCode.value) {
            return P1F01OpportunityAdmissionResult.alreadyAdmitted;
          }
          if (opportunityOrdinalWithinRun != expected ||
              lastOrdinal == opportunityOrdinalWithinRun) {
            await _markWindowLeftUnclean(txn, sequence);
            return P1F01OpportunityAdmissionResult.failedClosed;
          }

          await txn.update(
            _windowTable,
            {
              'admitted_o_raw_count':
                  (window['admitted_o_raw_count'] as int) + 1,
              'last_admitted_opportunity_ordinal': opportunityOrdinalWithinRun,
              'last_legal_set_code': legalSetCode.value,
            },
            where: 'local_window_sequence = ? AND status = ?',
            whereArgs: [
              sequence,
              P1F01IntegrityWindowStatus.open.storageValue,
            ],
          );
          await txn.rawInsert(
            '''
            INSERT INTO $_counterTable (
              local_window_sequence,
              legal_set_code,
              count
            ) VALUES (?, ?, 1)
            ON CONFLICT(local_window_sequence, legal_set_code)
            DO UPDATE SET count = count + 1
            ''',
            [sequence, legalSetCode.value],
          );
          if (_boundaryController.isAvailable) {
            await _boundaryController.reachedBeforeCommit();
          }
          return P1F01OpportunityAdmissionResult.admitted;
        });
        if (_boundaryController.isAvailable) {
          await _boundaryController.reachedAfterCommitBeforeAck();
        }
        return result;
      }),
    );
    return result ?? P1F01OpportunityAdmissionResult.failedClosed;
  }

  Future<bool> reconcileTerminal({
    required int opportunityOrdinalWithinRun,
    required bool terminalLinkAccepted,
  }) async {
    final result = await _guarded(
      P1F01IntegrityOperation.reconcileTerminal,
      () => _serialize(() async {
        final db = await _db();
        return db.transaction((txn) async {
          _fail(P1F01IntegrityOperation.reconcileTerminal);
          final window = await _latestOpenWindow(txn);
          if (window == null) return false;
          final sequence = window['local_window_sequence'] as int;
          final lastAdmitted =
              window['last_admitted_opportunity_ordinal'] as int?;
          final lastReconciled = window['last_reconciled_ordinal'] as int?;
          if (!terminalLinkAccepted ||
              lastAdmitted == null ||
              opportunityOrdinalWithinRun > lastAdmitted ||
              opportunityOrdinalWithinRun > (lastReconciled ?? 0) + 1) {
            await _markWindowLeftUnclean(txn, sequence);
            return false;
          }
          if (lastReconciled != null &&
              opportunityOrdinalWithinRun <= lastReconciled) {
            return true;
          }
          await txn.update(
            _windowTable,
            {'last_reconciled_ordinal': opportunityOrdinalWithinRun},
            where: 'local_window_sequence = ? AND status = ?',
            whereArgs: [
              sequence,
              P1F01IntegrityWindowStatus.open.storageValue,
            ],
          );
          return true;
        });
      }),
    );
    return result ?? false;
  }

  Future<bool> closeCleanIfConsistent() async {
    final result = await _guarded(
      P1F01IntegrityOperation.closeClean,
      () => _serialize(() async {
        final db = await _db();
        return db.transaction((txn) async {
          _fail(P1F01IntegrityOperation.closeClean);
          final window = await _latestOpenWindow(txn);
          if (window == null) return false;
          final sequence = window['local_window_sequence'] as int;
          final lastAdmitted =
              window['last_admitted_opportunity_ordinal'] as int?;
          final lastReconciled = window['last_reconciled_ordinal'] as int?;
          final hasDefect = window['known_integrity_defect'] == 1;
          if (hasDefect || lastAdmitted != lastReconciled) {
            await _markWindowLeftUnclean(txn, sequence);
            return false;
          }
          await txn.update(
            _windowTable,
            {
              'status': P1F01IntegrityWindowStatus.cleanlyClosed.storageValue,
              'clean_closure_signal': 1,
            },
            where: 'local_window_sequence = ? AND status = ?',
            whereArgs: [
              sequence,
              P1F01IntegrityWindowStatus.open.storageValue,
            ],
          );
          return true;
        });
      }),
    );
    return result ?? false;
  }

  Future<bool> markLeftUnclean() async {
    final result = await _guarded(
      P1F01IntegrityOperation.markLeftUnclean,
      () => _serialize(() async {
        final db = await _db();
        await db.transaction((txn) async {
          _fail(P1F01IntegrityOperation.markLeftUnclean);
          final window = await _latestOpenWindow(txn);
          if (window != null) {
            await _markWindowLeftUnclean(
              txn,
              window['local_window_sequence'] as int,
            );
          }
        });
        return true;
      }),
    );
    return result ?? false;
  }

  Future<bool> deleteAll() async {
    final result = await _guarded(
      P1F01IntegrityOperation.deleteAll,
      () => _serialize(() async {
        final db = await _db();
        await db.transaction((txn) async {
          _fail(P1F01IntegrityOperation.deleteAll);
          await txn.delete(_counterTable);
          await txn.delete(_windowTable);
        });
        return true;
      }),
    );
    return result ?? false;
  }

  Future<P1F01IntegritySnapshot?> latestSnapshot() async {
    await debugDrain();
    return _latestSnapshot();
  }

  Future<List<P1F01IntegritySnapshot>> retainedSnapshots() async {
    await _queue;
    final db = await _db();
    final rows = await db.query(
      _windowTable,
      orderBy: 'local_window_sequence ASC',
    );
    return List.unmodifiable(
      await Future.wait(rows.map((row) => _snapshotFromRow(db, row))),
    );
  }

  Future<void> drain() => _queue;

  @visibleForTesting
  Future<P1F01IntegritySnapshot?> snapshot(int localWindowSequence) async {
    await debugDrain();
    return _snapshot(localWindowSequence);
  }

  Future<P1F01IntegritySnapshot?> _latestSnapshot() async {
    final db = await _db();
    final rows = await db.query(
      _windowTable,
      orderBy: 'local_window_sequence DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _snapshotFromRow(db, rows.single);
  }

  Future<P1F01IntegritySnapshot?> _snapshot(int localWindowSequence) async {
    final db = await _db();
    final rows = await db.query(
      _windowTable,
      where: 'local_window_sequence = ?',
      whereArgs: [localWindowSequence],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _snapshotFromRow(db, rows.single);
  }

  @visibleForTesting
  Future<List<String>> debugColumnNames(String tableName) async {
    await debugDrain();
    final db = await _db();
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    return columns.map((column) => column['name'] as String).toList();
  }

  @visibleForTesting
  Future<List<P1F01IntegritySnapshot>> debugSnapshots() => retainedSnapshots();

  @visibleForTesting
  Future<void> debugDrain() => _queue;

  Future<void> close() async {
    await debugDrain();
    final db = _database;
    _database = null;
    await db?.close();
  }

  Future<Database> _db() async {
    final existing = _database;
    if (existing != null) return existing;
    final factory = _databaseFactory ?? databaseFactory;
    final path = _databasePath ?? await _defaultDatabasePath(factory);
    return _database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_windowTable (
              local_window_sequence INTEGER PRIMARY KEY AUTOINCREMENT,
              integrity_version INTEGER NOT NULL,
              status TEXT NOT NULL,
              admitted_o_raw_count INTEGER NOT NULL,
              last_admitted_opportunity_ordinal INTEGER,
              last_legal_set_code TEXT,
              last_reconciled_ordinal INTEGER,
              known_integrity_defect INTEGER NOT NULL DEFAULT 0,
              clean_closure_signal INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE $_counterTable (
              local_window_sequence INTEGER NOT NULL,
              legal_set_code TEXT NOT NULL,
              count INTEGER NOT NULL,
              PRIMARY KEY (local_window_sequence, legal_set_code),
              FOREIGN KEY (local_window_sequence)
                REFERENCES $_windowTable(local_window_sequence)
                ON DELETE CASCADE
            )
          ''');
        },
      ),
    );
  }

  Future<String> _defaultDatabasePath(DatabaseFactory factory) async {
    final base = await factory.getDatabasesPath();
    final separator = base.endsWith('/') || base.endsWith('\\') ? '' : '/';
    return '$base${separator}p1_f01_integrity.db';
  }

  Future<P1F01IntegritySnapshot> _snapshotFromRow(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final sequence = row['local_window_sequence'] as int;
    final counterRows = await db.query(
      _counterTable,
      columns: ['legal_set_code', 'count'],
      where: 'local_window_sequence = ?',
      whereArgs: [sequence],
    );
    return P1F01IntegritySnapshot(
      integrityVersion: row['integrity_version'] as int,
      localWindowSequence: sequence,
      status: P1F01IntegrityWindowStatus.fromStorage(row['status'] as String),
      admittedORawCount: row['admitted_o_raw_count'] as int,
      lastAdmittedOpportunityOrdinal:
          row['last_admitted_opportunity_ordinal'] as int?,
      lastLegalSetCode: row['last_legal_set_code'] as String?,
      lastReconciledOrdinal: row['last_reconciled_ordinal'] as int?,
      hasIntegrityDefect: row['known_integrity_defect'] == 1,
      hasCleanClosureSignal: row['clean_closure_signal'] == 1,
      legalSetCounters: Map.unmodifiable({
        for (final counter in counterRows)
          counter['legal_set_code'] as String: counter['count'] as int,
      }),
    );
  }

  Future<Map<String, Object?>?> _latestOpenWindow(
    DatabaseExecutor txn,
  ) async {
    final rows = await txn.query(
      _windowTable,
      where: 'status = ?',
      whereArgs: [P1F01IntegrityWindowStatus.open.storageValue],
      orderBy: 'local_window_sequence DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }

  Future<void> _markWindowLeftUnclean(
    DatabaseExecutor txn,
    int sequence,
  ) async {
    await txn.update(
      _windowTable,
      {
        'status': P1F01IntegrityWindowStatus.leftUnclean.storageValue,
        'known_integrity_defect': 1,
      },
      where: 'local_window_sequence = ? AND status = ?',
      whereArgs: [sequence, P1F01IntegrityWindowStatus.open.storageValue],
    );
  }

  Future<void> _pruneOldWindows(Transaction txn, int activeSequence) async {
    final retained = await txn.query(
      _windowTable,
      columns: ['local_window_sequence'],
      orderBy: 'local_window_sequence DESC',
      limit: _maxWindowRows,
    );
    final retainedSequences = retained
        .map((row) => row['local_window_sequence'] as int)
        .toSet()
      ..add(activeSequence);
    if (retainedSequences.length < _maxWindowRows) return;
    await txn.delete(
      _counterTable,
      where:
          'local_window_sequence NOT IN (${List.filled(retainedSequences.length, '?').join(',')})',
      whereArgs: retainedSequences.toList(),
    );
    await txn.delete(
      _windowTable,
      where:
          'local_window_sequence NOT IN (${List.filled(retainedSequences.length, '?').join(',')})',
      whereArgs: retainedSequences.toList(),
    );
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then<void>((_) {}, onError: (_, __) {});
    return next;
  }

  Future<T?> _guarded<T>(
    P1F01IntegrityOperation operation,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on Exception {
      return null;
    } on StateError {
      return null;
    }
  }

  void _fail(P1F01IntegrityOperation operation) => failureHook?.call(operation);
}
