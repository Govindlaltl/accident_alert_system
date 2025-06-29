package com.example.accident_alert_app   // ← change if package differs

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "accident/sms"
    private val ACTION_SMS_SENT = "ACCIDENT_ALERT_APP_SMS_SENT"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "sendSMS") {

                    val number = call.argument<String>("number")
                    val message = call.argument<String>("message")

                    if (number.isNullOrBlank() || message.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENTS",
                            "Both 'number' and 'message' are required.", null)
                        return@setMethodCallHandler
                    }

                    Log.d("SMS", "sendSMS called → $number")

                    /* ---------- PendingIntent template ---------- */
                    fun makePI(): PendingIntent = PendingIntent.getBroadcast(
                        this,
                        0,
                        Intent(ACTION_SMS_SENT),
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                            PendingIntent.FLAG_IMMUTABLE
                        else
                            0
                    )

                    /* ---------- BroadcastReceiver for each part ---------- */
                    val smsSentReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            Log.d("SMS", "resultCode=$resultCode")
                            unregisterReceiver(this)          // one‑shot
                        }
                    }

                    val brFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                        Context.RECEIVER_NOT_EXPORTED
                    else
                        0
                    registerReceiver(smsSentReceiver,
                        IntentFilter(ACTION_SMS_SENT), brFlags)

                    /* ---------- Send SMS via default subscription ---------- */
                    try {
                        val subId = SubscriptionManager.getDefaultSmsSubscriptionId()
                        val smsManager = SmsManager.getSmsManagerForSubscriptionId(subId)

                        val parts = smsManager.divideMessage(message)

                        // we need *one* sent‑intent per part
                        val sentIntents = ArrayList<PendingIntent>()
                        repeat(parts.size) { sentIntents.add(makePI()) }

                        smsManager.sendMultipartTextMessage(
                            number, null, parts, sentIntents, null
                        )

                        // Tell Flutter we queued the message successfully
                        result.success("SMS_DISPATCHED")

                    } catch (e: Exception) {
                        unregisterReceiver(smsSentReceiver)
                        result.error("EXCEPTION",
                            "Failed to send SMS: ${e.message}", null)
                    }

                } else {
                    result.notImplemented()
                }
            }
    }
}
