package com.mohamedk.mathchallenge

import android.app.Activity
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.SnapshotsClient
import com.google.android.gms.games.SnapshotsClient.SnapshotConflict
import com.google.android.gms.games.snapshot.Snapshot
import com.google.android.gms.games.snapshot.SnapshotContents
import com.google.android.gms.games.snapshot.SnapshotMetadataChange
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/** Byte-only bridge for the single Play Games Saved Games snapshot. */
class PlayGamesSavedGamesTransport(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private data class PendingConflict(
        val handle: String,
        val conflictId: String,
        val snapshotId: String,
        val resolutionSnapshotContents: SnapshotContents,
    )

    private var pendingConflict: PendingConflict? = null
    private var operationGeneration = 0L
    private val channel = MethodChannel(messenger, CHANNEL)

    fun register() {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openSnapshot" -> open(OnceResult(result))
                "commitSnapshot" -> commit(call, OnceResult(result))
                "resolveConflict" -> resolve(call, OnceResult(result))
                else -> result.notImplemented()
            }
        }
    }

    private fun open(result: OnceResult) {
        val generation = nextOperation(clearPendingConflict = true)
        authenticated(result, generation, "openFailed") {
            try {
                snapshots().open(SNAPSHOT_NAME, true, SnapshotsClient.RESOLUTION_POLICY_MANUAL)
                    .addOnCompleteListener { task ->
                        if (!isCurrent(result, generation, "openFailed")) {
                            return@addOnCompleteListener
                        }
                        if (!task.isSuccessful) {
                            result.success(failure("openFailed", task.exception))
                            return@addOnCompleteListener
                        }
                        try {
                            val dataOrConflict = task.result
                            if (dataOrConflict.isConflict) {
                                return@addOnCompleteListener mapConflict(
                                    dataOrConflict.conflict,
                                    result,
                                    generation,
                                    "openFailed",
                                )
                            }
                            val bytes = readBytes(dataOrConflict.data)
                            if (bytes == null) {
                                result.success(failure("readFailed"))
                            } else if (bytes.isEmpty()) {
                                result.success(response("openedEmpty"))
                            } else {
                                result.success(response("openedData", "bytes" to bytes))
                            }
                        } catch (error: Exception) {
                            result.success(failure("readFailed", error))
                        }
                    }
            } catch (error: Exception) {
                result.success(failure("unavailable", error))
            }
        }
    }

    private fun commit(call: MethodCall, result: OnceResult) {
        val generation = nextOperation(clearPendingConflict = true)
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes == null) {
            result.success(failure("invalidNativeResult"))
            return
        }
        authenticated(result, generation, "commitFailed") {
            try {
                val client = snapshots()
                client.open(SNAPSHOT_NAME, true, SnapshotsClient.RESOLUTION_POLICY_MANUAL)
                    .addOnCompleteListener { openTask ->
                        if (!isCurrent(result, generation, "commitFailed")) {
                            return@addOnCompleteListener
                        }
                        if (!openTask.isSuccessful) {
                            result.success(failure("openFailed", openTask.exception))
                            return@addOnCompleteListener
                        }
                        try {
                            val dataOrConflict = openTask.result
                            if (dataOrConflict.isConflict) {
                                return@addOnCompleteListener mapConflict(
                                    dataOrConflict.conflict,
                                    result,
                                    generation,
                                    "commitFailed",
                                )
                            }
                            val snapshot = dataOrConflict.data
                            if (snapshot == null) {
                                result.success(failure("invalidNativeResult"))
                                return@addOnCompleteListener
                            }
                            writeAndCommit(client, snapshot, bytes, result, generation)
                        } catch (error: Exception) {
                            result.success(failure("openFailed", error))
                        }
                    }
            } catch (error: Exception) {
                result.success(failure("unavailable", error))
            }
        }
    }

    private fun resolve(call: MethodCall, result: OnceResult) {
        val generation = nextOperation(clearPendingConflict = false)
        val handle = call.argument<String>("handle")
        val bytes = call.argument<ByteArray>("bytes")
        val pending = pendingConflict
        if (handle.isNullOrBlank() || bytes == null || pending?.handle != handle) {
            result.success(failure("staleConflictHandle"))
            return
        }
        authenticated(result, generation, "staleConflictHandle") {
            try {
                val client = snapshots()
                client.maxDataSize.addOnCompleteListener { maxTask ->
                    if (!isCurrent(result, generation, "staleConflictHandle")) {
                        return@addOnCompleteListener
                    }
                    if (!maxTask.isSuccessful) {
                        result.success(failure("writeFailed", maxTask.exception))
                        return@addOnCompleteListener
                    }
                    val maxDataSize = maxTask.result
                    if (maxDataSize == null) {
                        result.success(failure("invalidNativeResult"))
                        return@addOnCompleteListener
                    }
                    if (bytes.size > maxDataSize) {
                        result.success(failure("payloadTooLarge"))
                        return@addOnCompleteListener
                    }
                    try {
                        if (!isCurrent(result, generation, "staleConflictHandle")) {
                            return@addOnCompleteListener
                        }
                        pending.resolutionSnapshotContents.writeBytes(bytes)
                    } catch (error: Exception) {
                        result.success(failure("writeFailed", error))
                        return@addOnCompleteListener
                    }
                    try {
                        if (!isCurrent(result, generation, "staleConflictHandle")) {
                            return@addOnCompleteListener
                        }
                        client.resolveConflict(
                            pending.conflictId,
                            pending.snapshotId,
                            SnapshotMetadataChange.EMPTY_CHANGE,
                            pending.resolutionSnapshotContents,
                        )
                            .addOnCompleteListener { resolveTask ->
                                if (!isCurrent(result, generation, "staleConflictHandle")) {
                                    return@addOnCompleteListener
                                }
                                if (!resolveTask.isSuccessful) {
                                    result.success(failure("commitFailed", resolveTask.exception))
                                    return@addOnCompleteListener
                                }
                                try {
                                    val dataOrConflict = resolveTask.result
                                    if (dataOrConflict.isConflict) {
                                        mapConflict(
                                            dataOrConflict.conflict,
                                            result,
                                            generation,
                                            "staleConflictHandle",
                                        )
                                    } else if (dataOrConflict.data == null) {
                                        result.success(failure("invalidNativeResult"))
                                    } else {
                                        pendingConflict = null
                                        result.success(response("resolved"))
                                    }
                                } catch (error: Exception) {
                                    result.success(failure("invalidNativeResult", error))
                                }
                            }
                    } catch (error: Exception) {
                        result.success(failure("commitFailed", error))
                    }
                }
            } catch (error: Exception) {
                result.success(failure("unavailable", error))
            }
        }
    }

    private fun writeAndCommit(
        client: SnapshotsClient,
        snapshot: Snapshot,
        bytes: ByteArray,
        result: OnceResult,
        generation: Long,
    ) {
        client.maxDataSize.addOnCompleteListener { maxTask ->
            if (!isCurrent(result, generation, "commitFailed")) {
                return@addOnCompleteListener
            }
            if (!maxTask.isSuccessful) {
                result.success(failure("writeFailed", maxTask.exception))
                return@addOnCompleteListener
            }
            val maxDataSize = maxTask.result
            if (maxDataSize == null) {
                result.success(failure("invalidNativeResult"))
                return@addOnCompleteListener
            }
            if (bytes.size > maxDataSize) {
                result.success(failure("payloadTooLarge"))
                return@addOnCompleteListener
            }
            try {
                if (!isCurrent(result, generation, "commitFailed")) {
                    return@addOnCompleteListener
                }
                snapshot.snapshotContents.writeBytes(bytes)
            } catch (error: Exception) {
                result.success(failure("writeFailed", error))
                return@addOnCompleteListener
            }
            try {
                if (!isCurrent(result, generation, "commitFailed")) {
                    return@addOnCompleteListener
                }
                client.commitAndClose(snapshot, SnapshotMetadataChange.Builder().build())
                    .addOnCompleteListener { commitTask ->
                        if (!isCurrent(result, generation, "commitFailed")) {
                            return@addOnCompleteListener
                        }
                        if (commitTask.isSuccessful) {
                            result.success(response("committed"))
                        } else {
                            result.success(failure("commitFailed", commitTask.exception))
                        }
                    }
            } catch (error: Exception) {
                result.success(failure("commitFailed", error))
            }
        }
    }

    private fun mapConflict(
        conflict: SnapshotConflict?,
        result: OnceResult,
        generation: Long,
        staleCode: String,
    ) {
        if (!isCurrent(result, generation, staleCode)) {
            return
        }
        if (conflict == null) {
            result.success(failure("invalidNativeResult"))
            return
        }
        try {
            val snapshot = conflict.snapshot
            val conflictingSnapshot = conflict.conflictingSnapshot
            val resolutionSnapshotContents = conflict.resolutionSnapshotContents
            val snapshotId = snapshot?.metadata?.snapshotId
            val snapshotBytes = readBytes(snapshot)
            val conflictingBytes = readBytes(conflictingSnapshot)
            if (
                snapshot == null ||
                    snapshotId.isNullOrBlank() ||
                    resolutionSnapshotContents == null ||
                    snapshotBytes == null ||
                    conflictingBytes == null
            ) {
                result.success(failure("readFailed"))
                return
            }
            val handle = UUID.randomUUID().toString()
            pendingConflict = PendingConflict(
                handle,
                conflict.conflictId,
                snapshotId,
                resolutionSnapshotContents,
            )
            result.success(
                response(
                    "conflict",
                    "handle" to handle,
                    "snapshotBytes" to snapshotBytes,
                    "conflictingSnapshotBytes" to conflictingBytes,
                ),
            )
        } catch (error: Exception) {
            result.success(failure("readFailed", error))
        }
    }

    private fun readBytes(snapshot: Snapshot?): ByteArray? =
        snapshot?.snapshotContents?.readFully()

    private fun authenticated(
        result: OnceResult,
        generation: Long,
        staleCode: String,
        action: () -> Unit,
    ) {
        if (!PlayGamesInitialization.isInitialized) {
            result.success(failure("notAuthenticated"))
            return
        }
        try {
            PlayGames.getGamesSignInClient(activity).isAuthenticated
                .addOnCompleteListener { task ->
                    if (!isCurrent(result, generation, staleCode)) {
                        return@addOnCompleteListener
                    }
                    if (!task.isSuccessful) {
                        result.success(failure("unavailable", task.exception))
                    } else if (task.result.isAuthenticated) {
                        action()
                    } else {
                        result.success(failure("notAuthenticated"))
                    }
                }
        } catch (error: Exception) {
            result.success(failure("unavailable", error))
        }
    }

    private fun snapshots(): SnapshotsClient = PlayGames.getSnapshotsClient(activity)

    private fun nextOperation(clearPendingConflict: Boolean): Long {
        operationGeneration++
        if (clearPendingConflict) pendingConflict = null
        return operationGeneration
    }

    private fun isCurrent(result: OnceResult, generation: Long, staleCode: String): Boolean {
        if (generation == operationGeneration) return true
        result.success(failure(staleCode))
        return false
    }

    private fun response(status: String, vararg values: Pair<String, Any?>): Map<String, Any?> =
        mapOf("status" to status, *values)

    private fun failure(code: String, error: Exception? = null): Map<String, Any?> =
        response("failure", "errorCode" to code, "diagnostic" to error?.message)

    private class OnceResult(private val delegate: MethodChannel.Result) {
        private var completed = false

        fun success(value: Any?) {
            if (!completed) {
                completed = true
                delegate.success(value)
            }
        }
    }

    private companion object {
        const val CHANNEL = "math_challenge/play_games_saved_games"
        const val SNAPSHOT_NAME = "math-challenge-progress-v1"
    }
}
