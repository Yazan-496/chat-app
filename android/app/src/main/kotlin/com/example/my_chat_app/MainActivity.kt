package com.example.my_chat_app

import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.net.Uri
import android.provider.Settings
import android.content.Context
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.graphics.drawable.IconCompat
import androidx.core.content.getSystemService
import androidx.core.content.LocusIdCompat
import androidx.core.app.Person
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import android.app.PendingIntent
import android.graphics.BitmapFactory
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

import android.view.KeyEvent
import android.view.KeyboardShortcutGroup
import android.view.KeyboardShortcutInfo
import android.view.Menu

open class MainActivity : FlutterActivity() {
    private val channelName = "com.example.my_chat_app/bubbles"
    private var methodChannel: MethodChannel? = null
    private val messagesChannelId = "messages_channel_v7"
    private var lastBubbleChatId: String? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return getOrCreateEngine(context)
    }

    override fun onProvideKeyboardShortcuts(
        data: MutableList<KeyboardShortcutGroup>?,
        menu: Menu?,
        deviceId: Int
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val shortcuts = ArrayList<KeyboardShortcutInfo>()
            shortcuts.add(KeyboardShortcutInfo("Send Message", KeyEvent.KEYCODE_ENTER, 0))
            data?.add(KeyboardShortcutGroup("Chat", shortcuts))
        }
        super.onProvideKeyboardShortcuts(data, menu, deviceId)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        ensureBackgroundServiceChannel()
        ensureMessagesChannel()

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getLaunchChatId" -> {
                    val chatId = intent?.getStringExtra("chat_id") ?: intent?.getStringExtra("chatid") ?: ""
                    result.success(chatId)
                }
                "isBubble" -> {
                    val fromBubble = intent?.getBooleanExtra("from_bubble", false) ?: false
                    result.success(fromBubble)
                }
                "showBubble" -> {
                    try {
                        val args = call.arguments as? Map<*, *>
                        val chatId = (args?.get("chat_id") as? String).orEmpty()
                        val title = (args?.get("title") as? String).orEmpty()
                        val body = (args?.get("body") as? String).orEmpty()
                        val avatarPath = args?.get("avatar_path") as? String
                        val autoExpand = (args?.get("auto_expand") as? Boolean) ?: false
                        if (chatId.isBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        showBubbleNotification(chatId, title, body, avatarPath, autoExpand)
                        lastBubbleChatId = chatId
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("LoZoBubble", "showBubble failed", e)
                        result.error("BUBBLE_ERROR", e.message, null)
                    }
                }
                "hideBubble" -> {
                    try {
                        val chatId = lastBubbleChatId.orEmpty()
                        if (chatId.isBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        NotificationManagerCompat.from(this).cancel(chatId.hashCode())
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("LoZoBubble", "hideBubble failed", e)
                        result.error("BUBBLE_ERROR", e.message, null)
                    }
                }
                "updateBubbleData" -> {
                    try {
                        val args = call.arguments as? Map<*, *>
                        val chatIdArg = (args?.get("chat_id") as? String).orEmpty()
                        val title = (args?.get("title") as? String).orEmpty()
                        val body = (args?.get("body") as? String).orEmpty()
                        val chatId = if (chatIdArg.isNotBlank()) chatIdArg else lastBubbleChatId.orEmpty()
                        if (chatId.isBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        showBubbleNotification(chatId, title, body, null, false, true)
                        lastBubbleChatId = chatId
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("LoZoBubble", "updateBubbleData failed", e)
                        result.error("BUBBLE_ERROR", e.message, null)
                    }
                }
                "canShowBubbles" -> {
                    try {
                        result.success(canShowBubbles())
                    } catch (e: Exception) {
                        Log.e("LoZoBubble", "canShowBubbles failed", e)
                        result.success(false)
                    }
                }
                "canDrawOverlays" -> {
                    result.success(false)
                }
                "moveTaskToBack" -> {
                    moveTaskToBack(true)
                    result.success(true)
                }
                "getAndroidVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                "requestBatteryOptimization" -> {
                    requestBatteryOptimization()
                    result.success(true)
                }
                "requestBubblePermission" -> {
                    requestBubblePermission()
                    result.success(true)
                }
                "requestOverlayPermission" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val ENGINE_ID = "main_engine"

        fun getOrCreateEngine(context: Context): FlutterEngine {
            val cache = FlutterEngineCache.getInstance()
            val cached = cache.get(ENGINE_ID)
            if (cached != null) return cached
            val engine = FlutterEngine(context.applicationContext)
            engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
            cache.put(ENGINE_ID, engine)
            return engine
        }
    }

    private fun ensureBackgroundServiceChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService<NotificationManager>() ?: return
        
        val channelId = "my_chat_app_background"
        if (manager.getNotificationChannel(channelId) != null) return

        val channel = NotificationChannel(
            channelId,
            "Background Service",
            NotificationManager.IMPORTANCE_MIN
        )
        channel.description = "Running in background to receive messages"
        channel.setShowBadge(false)
        manager.createNotificationChannel(channel)
    }

    private fun isAppBubbleAllowed(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val manager = getSystemService<NotificationManager>() ?: return false
        
        // On Android 11 (R) and above, areBubblesAllowed() checks the app-level permission.
        // It returns true if "All conversations can bubble" or "Selected conversations can bubble".
        // It returns false ONLY if "Nothing can bubble".
        val allowed = try { manager.areBubblesAllowed() } catch (_: Exception) { false }
        
        // Log for debugging
        Log.d("LoZoBubble", "isAppBubbleAllowed: $allowed (SDK ${Build.VERSION.SDK_INT})")
        
        return allowed
    }

    private fun canShowBubbles(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        ensureMessagesChannel()
        val manager = getSystemService<NotificationManager>() ?: return false
        val appAllowed = try { manager.areBubblesAllowed() } catch (_: Exception) { false }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = manager.getNotificationChannel(messagesChannelId) ?: return true
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val channelAllowed = channel.canBubble()
                Log.d(
                    "LoZoBubble",
                    "canShowBubbles sdk=${Build.VERSION.SDK_INT} channelId=$messagesChannelId appAllowed=$appAllowed channelAllowed=$channelAllowed importance=${channel.importance}"
                )
                return appAllowed && channelAllowed
            }
        }
        Log.d(
            "LoZoBubble",
            "canShowBubbles sdk=${Build.VERSION.SDK_INT} channelId=$messagesChannelId appAllowed=$appAllowed channelAllowed=true"
        )
        return appAllowed
    }

    private fun ensureMessagesChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService<NotificationManager>() ?: return
        val existing = manager.getNotificationChannel(messagesChannelId)
        if (existing != null) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    existing.setAllowBubbles(true)
                    manager.createNotificationChannel(existing)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    val appAllowed = try { manager.areBubblesAllowed() } catch (_: Exception) { false }
                    val channelAllowed = try { existing.canBubble() } catch (_: Exception) { false }
                    if (appAllowed && !channelAllowed) {
                        try {
                            manager.deleteNotificationChannel(messagesChannelId)
                        } catch (_: Exception) {}
                        Log.d(
                            "LoZoBubble",
                            "Recreating channel for bubbles: appAllowed=$appAllowed channelAllowed=$channelAllowed"
                        )
                        createMessagesChannel(manager)
                    }
                }
            } catch (_: Exception) {}
            return
        }
        createMessagesChannel(manager)
    }

    private fun createMessagesChannel(manager: NotificationManager) {
        val channel = NotificationChannel(
            messagesChannelId,
            "Messages",
            NotificationManager.IMPORTANCE_MAX
        )
        channel.description = "Notifications for new messages"
        channel.setShowBadge(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            channel.setAllowBubbles(true)
        }
        manager.createNotificationChannel(channel)
    }

    private fun createAdaptiveIcon(path: String): IconCompat? {
        if (path.isBlank()) return null
        return try {
            val original = BitmapFactory.decodeFile(path) ?: return null
            val size = original.width.coerceAtMost(original.height)
            // Create a larger canvas to allow padding (zooming out the avatar)
            // Adaptive icons viewport is 72dp inside 108dp canvas.
            // If we fill the canvas, it looks "zoomed in".
            // We scale it down slightly to fit the face better in the circle.
            val opaque = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(opaque)
            canvas.drawColor(android.graphics.Color.WHITE) // Background
            
            val srcRect: Rect
            if (original.width > original.height) {
                 val left = (original.width - original.height) / 2
                 srcRect = Rect(left, 0, left + original.height, original.height)
            } else {
                 val top = (original.height - original.width) / 2
                 srcRect = Rect(0, top, original.width, top + original.width)
            }
            
            // Draw with 10% padding (zoom out)
            val padding = (size * 0.1f).toInt()
            val dstRect = Rect(padding, padding, size - padding, size - padding)
            
            canvas.drawBitmap(original, srcRect, dstRect, null)
            
            IconCompat.createWithAdaptiveBitmap(opaque)
        } catch (e: Exception) {
            Log.e("LoZoBubble", "createAdaptiveIcon failed", e)
            null
        }
    }

    private fun showBubbleNotification(chatId: String, title: String, body: String, avatarPath: String?, autoExpand: Boolean, suppressNotification: Boolean = false) {
        if (chatId.isBlank()) return
        ensureMessagesChannel()

        val manager = getSystemService<NotificationManager>()
        val appAllowed = try { manager?.areBubblesAllowed() == true } catch (_: Exception) { false }

        ensureConversationShortcut(chatId, title, avatarPath)

        val intent = Intent(this, BubbleActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("https://lozo.chat/chat/$chatId")
            putExtra("chat_id", chatId)
            putExtra("chatid", chatId)
            putExtra("from_bubble", true)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        }
        val pendingIntent = PendingIntent.getActivity(this, chatId.hashCode(), intent, flags)
        
        var bubbleIcon = IconCompat.createWithContentUri(Uri.parse("android.resource://$packageName/${R.mipmap.ic_launcher}"))
        if (!avatarPath.isNullOrBlank()) {
             val adaptive = createAdaptiveIcon(avatarPath!!)
             if (adaptive != null) {
                 bubbleIcon = adaptive
             }
        }

        val bubbleMeta = NotificationCompat.BubbleMetadata.Builder(pendingIntent, bubbleIcon)
            .setDesiredHeight(800)
            .setAutoExpandBubble(autoExpand)
            .setSuppressNotification(appAllowed || suppressNotification)
            .build()

        val personBuilder = Person.Builder().setName(title.ifBlank { "Messages" })
        val personIcon = if (!avatarPath.isNullOrBlank()) {
            createAdaptiveIcon(avatarPath!!)
        } else {
            null
        }
        if (personIcon != null) {
            personBuilder.setIcon(personIcon)
        }
        val person = personBuilder.build()

        val messagingStyle = NotificationCompat.MessagingStyle(person)
            .addMessage(body.ifBlank { "Tap to chat" }, System.currentTimeMillis(), person)

        val notification = NotificationCompat.Builder(this, messagesChannelId)
            .setSmallIcon(R.drawable.ic_stat_lozo)
            .setContentTitle(title.ifBlank { "Messages" })
            .setContentText(body.ifBlank { "Tap to chat" })
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setShortcutId(chatId)
            .setLocusId(LocusIdCompat(chatId))
            .setStyle(messagingStyle)
            .setBubbleMetadata(bubbleMeta)
            
        if (suppressNotification) {
            notification.setOnlyAlertOnce(true)
        }

        val builtNotification = notification.build()

        try {
            NotificationManagerCompat.from(this).notify(chatId.hashCode(), builtNotification)
            Log.d("LoZoBubble", "Bubble posted chatId=$chatId title=$title sdk=${Build.VERSION.SDK_INT} bubblesAllowed=$appAllowed suppressed=$suppressNotification")
        } catch (e: Exception) {
            Log.e(
                "LoZoBubble",
                "notify failed chatId=$chatId sdk=${Build.VERSION.SDK_INT} enabled=${NotificationManagerCompat.from(this).areNotificationsEnabled()}",
                e
            )
            throw e
        }
    }

    private fun ensureConversationShortcut(chatId: String, title: String, avatarPath: String?) {
        try {
            if (!ShortcutManagerCompat.isRequestPinShortcutSupported(this)) {
                // Still OK; dynamic shortcuts can work even if pin not supported.
            }
            val shortcutIntent = Intent(this, BubbleActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://lozo.chat/chat/$chatId")
                putExtra("chat_id", chatId)
                putExtra("chatid", chatId)
                putExtra("from_bubble", true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            }

            var icon = IconCompat.createWithResource(this, R.mipmap.ic_launcher)
            if (!avatarPath.isNullOrBlank()) {
                 val adaptive = createAdaptiveIcon(avatarPath!!)
                 if (adaptive != null) {
                     icon = adaptive
                 }
            }

            val personBuilder = Person.Builder().setName(title.ifBlank { "Messages" })
            if (!avatarPath.isNullOrBlank()) {
                personBuilder.setIcon(icon)
            }
            val person = personBuilder.build()

            val shortcut = ShortcutInfoCompat.Builder(this, chatId)
                .setShortLabel(title.ifBlank { "Chat" })
                .setLongLabel(title.ifBlank { "Chat" })
                .setIcon(icon)
                .setIntent(shortcutIntent)
                .setLongLived(true)
                .setPerson(person)
                .build()

            ShortcutManagerCompat.removeDynamicShortcuts(this, listOf(chatId))
            ShortcutManagerCompat.pushDynamicShortcut(this, shortcut)
        } catch (e: Exception) {
            Log.e("LoZoBubble", "ensureConversationShortcut failed chatId=$chatId", e)
        }
    }

    private fun requestBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent()
            val packageName = packageName
            val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                intent.data = Uri.parse("package:$packageName")
                try {
                    startActivity(intent)
                } catch (_: Exception) {}
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra("from_bubble", false)) {
            return
        }
        if (intent.action == Intent.ACTION_MAIN) {
            return
        }
        val chatId = intent.getStringExtra("chat_id") ?: intent.getStringExtra("chatid") ?: ""
        try {
            methodChannel?.invokeMethod("onLaunchChatId", mapOf("chat_id" to chatId))
        } catch (_: Exception) {}
    }

    private fun requestBubblePermission() {
        fun tryStart(intent: Intent): Boolean {
            return try {
                startActivity(intent)
                true
            } catch (_: Exception) {
                false
            }
        }

        fun openChannelSettings(): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
            val intent = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                putExtra(Settings.EXTRA_CHANNEL_ID, messagesChannelId)
                putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
            }
            return tryStart(intent)
        }

        fun openAppBubbleSettings(): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_BUBBLE_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
            }
            return tryStart(intent)
        }

        fun openAppDetailsSettings(): Boolean {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                addCategory(Intent.CATEGORY_DEFAULT)
                data = Uri.parse("package:$packageName")
            }
            return tryStart(intent)
        }

        ensureMessagesChannel()

        val manager = getSystemService<NotificationManager>()
        val appAllowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && manager != null) {
            try { manager.areBubblesAllowed() } catch (_: Exception) { false }
        } else {
            false
        }
        val channelAllowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && manager != null) {
            try { manager.getNotificationChannel(messagesChannelId)?.canBubble() ?: false } catch (_: Exception) { false }
        } else {
            true
        }

        // Try the specific Bubble setting first and exclusively if possible.
        if (openAppBubbleSettings()) return
        
        // If not supported (e.g. Android Q), try global bubble settings.
        if (tryStart(Intent("android.settings.BUBBLE_SETTINGS"))) return
        if (tryStart(Intent("android.settings.MANAGE_BUBBLE_SETTINGS"))) return
        
        // Fallback to open channel settings which might contain bubble settings on some devices,
        // but avoid general app notification settings if possible as user requested.
        if (openChannelSettings()) return
        
        openAppDetailsSettings()
    }
}
