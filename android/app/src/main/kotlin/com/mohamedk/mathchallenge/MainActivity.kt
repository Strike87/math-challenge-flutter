package com.mohamedk.mathchallenge

import android.content.Intent
import android.net.Uri
import com.google.android.gms.games.PlayGames
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "math_challenge/link_launcher"
        ).setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val url = call.argument<String>("url")
            if (url.isNullOrBlank()) {
                result.success(false)
                return@setMethodCallHandler
            }

            try {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                startActivity(intent)
                result.success(true)
            } catch (_: Exception) {
                result.success(false)
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "math_challenge/play_games"
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "isAuthenticated" -> {
                        PlayGames.getGamesSignInClient(this).isAuthenticated
                            .addOnCompleteListener { task ->
                                if (task.isSuccessful) {
                                    result.success(task.result.isAuthenticated)
                                } else {
                                    result.error("PGS_AUTH", task.exception?.message, null)
                                }
                            }
                    }
                    "connect" -> {
                        PlayGames.getGamesSignInClient(this).signIn()
                            .addOnCompleteListener { task ->
                                if (task.isSuccessful) {
                                    result.success(task.result.isAuthenticated)
                                } else {
                                    result.success(false)
                                }
                            }
                    }
                    "unlockAchievement" -> {
                        val achievementId = call.argument<String>("achievementId")
                        if (achievementId.isNullOrBlank()) {
                            result.error("PGS_ARGUMENT", "Missing achievementId", null)
                            return@setMethodCallHandler
                        }
                        PlayGames.getAchievementsClient(this).unlock(achievementId)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("PGS_UNAVAILABLE", error.message, null)
            }
        }

        PlayGamesSavedGamesTransport(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
        ).register()
    }
}
