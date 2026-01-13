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
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
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
                    val profilePicUrl = args?.get("profilePicUrl") as? String
                    showConversationBubble(chatId, title, body, profilePicUrl)
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

    private fun showConversationBubble(chatId: String, title: String, body: String, profilePicUrl: String?) {
        if (profilePicUrl != null && profilePicUrl.isNotEmpty()) {
            thread {
                try {
                    val url = URL(profilePicUrl)
                    val connection = url.openConnection() as HttpURLConnection
                    connection.doInput = true
                    connection.connect()
                    val input = connection.inputStream
                    val bitmap = BitmapFactory.decodeStream(input)
                    if (bitmap != null) {
                        val circularBitmap = getCircularBitmap(bitmap)
                        val icon = IconCompat.createWithBitmap(circularBitmap)
                        runOnUiThread {
                            buildAndShowBubble(chatId, title, body, icon)
                        }
                    } else {
                        runOnUiThread {
                            buildAndShowBubble(chatId, title, body, null)
                        }
                    }
                } catch (e: Exception) {
                    runOnUiThread {
                        buildAndShowBubble(chatId, title, body, null)
                    }
                }
            }
        } else {
            buildAndShowBubble(chatId, title, body, null)
        }
    }

    private fun getCircularBitmap(bitmap: Bitmap): Bitmap {
        val output = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val color = -0xbdbdbe
        val paint = Paint()
        val rect = Rect(0, 0, bitmap.width, bitmap.height)
        val rectF = RectF(rect)
        val roundPx = (if (bitmap.width < bitmap.height) bitmap.width / 2 else bitmap.height / 2).toFloat()
        paint.isAntiAlias = true
        canvas.drawARGB(0, 0, 0, 0)
        paint.color = color
        canvas.drawCircle(roundPx, roundPx, roundPx, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(bitmap, rect, rect, paint)
        return output
    }

    private fun buildAndShowBubble(chatId: String, title: String, body: String, profileIcon: IconCompat?) {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            putExtra("chatId", chatId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val mutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        val bubbleIntent = PendingIntent.getActivity(this, chatId.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or mutableFlag)

        val defaultIcon = IconCompat.createWithResource(this, R.mipmap.ic_launcher)
        val icon = profileIcon ?: defaultIcon
        
        val person = Person.Builder().setName(title).setIcon(icon).build()
        val me = Person.Builder().setName("You").setIcon(defaultIcon).build()

        val bubble = NotificationCompat.BubbleMetadata.Builder(bubbleIntent, icon)
            .setDesiredHeightResId(R.dimen.bubble_height)
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
