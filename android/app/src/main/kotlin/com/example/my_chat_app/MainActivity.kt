package com.example.my_chat_app

import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.Manifest
import android.net.Uri
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import androidx.core.content.LocusIdCompat
import android.app.PendingIntent
import androidx.core.app.ActivityCompat
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.my_chat_app/bubbles"
    private val notificationChannelId = "chat_channel"
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showBubble" -> {
                    val args = call.arguments as? Map<*, *>
                    val chatId = args?.get("chatId") as? String ?: ""
                    val title = args?.get("title") as? String ?: "Chat"
                    val body = args?.get("body") as? String ?: "Open conversation"
                    showConversationBubble(chatId, title, body)
                    result.success(true)
                }
                "getLaunchChatId" -> {
                    val chatId = intent?.getStringExtra("chatId") ?: ""
                    result.success(chatId)
                }
                "requestBubblePermission" -> {
                    requestBubblePermission()
                    result.success(true)
                }
                "isBubblePermissionReady" -> {
                    result.success(isBubblePermissionReady())
                }
                "moveTaskToBack" -> {
                    moveTaskToBack(true)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val chatId = intent.getStringExtra("chatId") ?: ""
        try {
            methodChannel.invokeMethod("onLaunchChatId", mapOf("chatId" to chatId))
        } catch (_: Exception) {}
    }

    private fun requestBubblePermission() {
        if (isBubblePermissionReady()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val hasPost = checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
            if (!hasPost) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
            }
        }
        val notifSettingsIntent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        try {
            startActivity(notifSettingsIntent)
        } catch (_: Exception) {}

        if (!Settings.canDrawOverlays(this)) {
            val overlayIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
            try {
                startActivity(overlayIntent)
            } catch (_: Exception) {}
        }
    }

    private fun isBubblePermissionReady(): Boolean {
        val notifEnabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
        val overlay = Settings.canDrawOverlays(this)
        val postGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else true
        return notifEnabled && overlay && postGranted
    }

    private fun showConversationBubble(chatId: String, title: String, body: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            putExtra("chatId", chatId)
        }
        val mutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        val bubbleIntent = PendingIntent.getActivity(this, chatId.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or mutableFlag)

        val icon = IconCompat.createWithResource(this, R.mipmap.ic_launcher)
        val person = Person.Builder().setName(title).setIcon(icon).build()
        val me = Person.Builder().setName("You").setIcon(icon).build()

        val bubble = NotificationCompat.BubbleMetadata.Builder(bubbleIntent, icon)
            .setDesiredHeight(600)
            .setAutoExpandBubble(true)
            .setSuppressNotification(false)
            .build()

        val shortcut = ShortcutInfoCompat.Builder(this, "chat_$chatId")
            .setLocusId(LocusIdCompat("chat_$chatId"))
            .setActivity(ComponentName(this, MainActivity::class.java))
            .setShortLabel(title)
            .setLongLived(true)
            .setIcon(icon)
            .setIntent(intent)
            .build()
        try {
            ShortcutManagerCompat.pushDynamicShortcut(this, shortcut)
        } catch (_: Exception) {}

        val style = NotificationCompat.MessagingStyle(me)
            .setConversationTitle(title)
            .setGroupConversation(true)
            .addMessage(body, System.currentTimeMillis(), person)

        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCategory(android.app.Notification.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(bubbleIntent)
            .setStyle(style)
            .setBubbleMetadata(bubble)
            .setShortcutInfo(shortcut)
            .addPerson(person)
            .setAutoCancel(true)
            .build()

        try {
            NotificationManagerCompat.from(this).notify(chatId.hashCode(), notification)
        } catch (_: Exception) {}
    }
}
