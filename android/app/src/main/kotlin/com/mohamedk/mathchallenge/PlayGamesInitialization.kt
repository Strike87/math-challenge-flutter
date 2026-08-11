package com.mohamedk.mathchallenge

import android.content.Context
import com.google.android.gms.games.PlayGamesSdk

object PlayGamesInitialization {
    @Volatile
    var isInitialized = false
        private set

    @Synchronized
    fun initialize(context: Context) {
        if (isInitialized) return
        PlayGamesSdk.initialize(context.applicationContext)
        isInitialized = true
    }
}
