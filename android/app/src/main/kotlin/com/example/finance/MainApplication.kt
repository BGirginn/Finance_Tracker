package com.example.finance

import io.flutter.app.FlutterApplication
import androidx.work.Configuration

class MainApplication : FlutterApplication(), Configuration.Provider {
    override fun onCreate() {
        super.onCreate()
    }

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()
}
