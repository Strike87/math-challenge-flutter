package com.mohamedk.mathchallenge

import android.app.Application
import com.google.android.gms.games.PlayGamesSdk

class MathChallengeApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        PlayGamesSdk.initialize(this)
    }
}
