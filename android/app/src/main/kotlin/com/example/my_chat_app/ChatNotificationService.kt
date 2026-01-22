package com.example.my_chat_app

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import android.os.Build
import androidx.annotation.Keep
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.app.RemoteInput
import androidx.core.content.LocusIdCompat
import androidx.core.content.getSystemService
import androidx.core.graphics.drawable.IconCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import com.onesignal.notifications.INotificationReceivedEvent
import com.onesignal.notifications.INotificationServiceExtension
import java.net.URL

@Keep
class ChatNotificationService : INotificationServiceExtension {
    override fun onNotificationReceived(event: INotificationReceivedEvent) {
        val notification = event.notification
        val data = notification.additionalData
        val chatId = data?.optString("chat_id") ?: ""
        if (chatId.isBlank()) {
            return
        }

        event.preventDefault()

        val context = event.context
        val senderName = data?.optString("sender_name").orEmpty()
        val title = senderName.ifBlank { notification.title ?: "Messages" }
        val body = data?.optString("message_body").orEmpty().ifBlank { notification.body ?: "New message" }
        val messageId = data?.optString("message_id").orEmpty()
        val unreadCount = data?.optInt("unread_count", 0) ?: 0
        val avatarUrl = data?.optString("sender_profile_url").orEmpty().ifBlank { null }
        val avatarColor = data?.let { parseAvatarColor(it) } ?: DEFAULT_AVATAR_COLOR

        val contentIntent = createContentIntent(context, chatId)
        val replyAction = createReplyAction(context, chatId, messageId)
        val markReadAction = createMarkReadAction(context, chatId)

        val avatarBitmap = loadAvatarBitmap(context, avatarUrl, avatarColor, title, senderName.isNotBlank())
        val avatarAdaptiveIcon = avatarBitmap?.let { createAdaptiveIcon(it) }
        val avatarIcon = avatarAdaptiveIcon ?: avatarBitmap?.let { IconCompat.createWithBitmap(it) }
        val fallbackIcon = IconCompat.createWithResource(context, R.mipmap.ic_launcher)
        val sender = Person.Builder().setName(title).apply {
            setIcon(avatarIcon ?: fallbackIcon)
        }.build()
        val messagingStyle = NotificationCompat.MessagingStyle(sender)
            .addMessage(body, System.currentTimeMillis(), sender)

        val groupKey = "chat_$chatId"
        val notificationId = chatId.hashCode()

        ensureConversationShortcut(context, chatId, title, avatarIcon)

        val builder = NotificationCompat.Builder(context, "messages_channel_v7")
            .setSmallIcon(R.drawable.ic_stat_lozo)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(contentIntent)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setStyle(messagingStyle)
            .setShortcutId(chatId)
            .setLocusId(LocusIdCompat(chatId))
            .setGroup(groupKey)
            .setLargeIcon(avatarBitmap)
            .addAction(markReadAction)
            .addAction(replyAction)

        val bubbleMetadata = createBubbleMetadata(context, chatId, avatarIcon)
        if (bubbleMetadata != null) {
            builder.setBubbleMetadata(bubbleMetadata)
        }

        NotificationManagerCompat.from(context).notify(notificationId, builder.build())

        if (unreadCount > 1) {
            val summaryId = notificationId * 31
            val summaryBuilder = NotificationCompat.Builder(context, "messages_channel_v7")
                .setSmallIcon(R.drawable.ic_stat_lozo)
                .setContentTitle(title)
                .setContentText("$unreadCount new messages")
                .setGroup(groupKey)
                .setGroupSummary(true)
                .setAutoCancel(true)
            NotificationManagerCompat.from(context).notify(summaryId, summaryBuilder.build())
        }
    }

    private fun createContentIntent(context: Context, chatId: String): PendingIntent {
        val intent = Intent(context, BubbleActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("https://lozo.chat/chat/$chatId")
            putExtra("chat_id", chatId)
            putExtra("chatid", chatId)
            putExtra("from_bubble", true)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getActivity(context, chatId.hashCode(), intent, flags)
    }

    private fun createReplyAction(
        context: Context,
        chatId: String,
        messageId: String,
    ): NotificationCompat.Action {
        val remoteInput = RemoteInput.Builder(NotificationActionReceiver.KEY_TEXT_REPLY)
            .setLabel("Reply")
            .build()
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_REPLY
            putExtra(NotificationActionReceiver.EXTRA_CHAT_ID, chatId)
            putExtra(NotificationActionReceiver.EXTRA_MESSAGE_ID, messageId)
            putExtra(NotificationActionReceiver.EXTRA_NOTIFICATION_ID, chatId.hashCode())
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        }
        val pendingIntent = PendingIntent.getBroadcast(context, chatId.hashCode(), intent, flags)
        return NotificationCompat.Action.Builder(
            0,
            "Reply",
            pendingIntent,
        ).addRemoteInput(remoteInput).build()
    }

    private fun createMarkReadAction(context: Context, chatId: String): NotificationCompat.Action {
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_MARK_READ
            putExtra(NotificationActionReceiver.EXTRA_CHAT_ID, chatId)
            putExtra(NotificationActionReceiver.EXTRA_NOTIFICATION_ID, chatId.hashCode())
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        }
        val pendingIntent = PendingIntent.getBroadcast(context, chatId.hashCode() + 1, intent, flags)
        return NotificationCompat.Action.Builder(
            0,
            "Mark as read",
            pendingIntent,
        ).build()
    }

    private fun createBubbleMetadata(
        context: Context,
        chatId: String,
        avatarIcon: IconCompat?,
    ): NotificationCompat.BubbleMetadata? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val manager = context.getSystemService<NotificationManager>() ?: return null
        val appAllowed = try { manager.areBubblesAllowed() } catch (_: Exception) { false }
        val bubbleIntent = Intent(context, BubbleActivity::class.java).apply {
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
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        }
        val pendingIntent = PendingIntent.getActivity(context, chatId.hashCode(), bubbleIntent, flags)
        val icon = avatarIcon ?: IconCompat.createWithResource(context, R.mipmap.ic_launcher)
        return NotificationCompat.BubbleMetadata.Builder(pendingIntent, icon)
            .setDesiredHeight(800)
            .setAutoExpandBubble(false)
            .setSuppressNotification(appAllowed)
            .build()
    }

    private fun ensureConversationShortcut(
        context: Context,
        chatId: String,
        title: String,
        avatarIcon: IconCompat?,
    ) {
        val person = Person.Builder().setName(title).apply {
            if (avatarIcon != null) setIcon(avatarIcon)
        }.build()
        val shortcutIcon = avatarIcon ?: IconCompat.createWithResource(context, R.mipmap.ic_launcher)
        val shortcut = ShortcutInfoCompat.Builder(context, chatId)
            .setShortLabel(title.ifBlank { "Messages" })
            .setLongLived(true)
            .setPerson(person)
            .setIcon(shortcutIcon)
            .setIntent(Intent(context, BubbleActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("https://lozo.chat/chat/$chatId")
                putExtra("chat_id", chatId)
                putExtra("chatid", chatId)
                putExtra("from_bubble", true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            })
            .build()
        ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
    }

    private fun loadAvatarBitmap(
        context: Context,
        avatarUrl: String?,
        avatarColor: Int,
        title: String,
        preferLetterFallback: Boolean,
    ): Bitmap? {
        if (!avatarUrl.isNullOrBlank()) {
            try {
                val url = URL(avatarUrl)
                url.openStream().use { stream ->
                    val bitmap = BitmapFactory.decodeStream(stream)
                    if (bitmap != null) return scaleAvatarBitmap(bitmap)
                }
            } catch (_: Exception) {}
        }
        if (preferLetterFallback) {
            return createLetterAvatarBitmap(title, avatarColor)
        }
        return loadAppIconBitmap(context) ?: createLetterAvatarBitmap(title, avatarColor)
    }

    private fun loadAppIconBitmap(context: Context, size: Int = 384): Bitmap? {
        val drawable = try {
            context.packageManager.getApplicationIcon(context.packageName)
        } catch (_: Exception) {
            null
        } ?: return null
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            val bitmap = drawable.bitmap
            return scaleAvatarBitmap(bitmap, size)
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else size
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else size
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return scaleAvatarBitmap(bitmap, size)
    }

    private fun createLetterAvatarBitmap(name: String, color: Int, size: Int = 384): Bitmap {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = color
        canvas.drawCircle(size / 2f, size / 2f, size / 2f, paint)
        val letter = name.trim().firstOrNull()?.toString()?.uppercase() ?: "?"
        paint.color = Color.WHITE
        paint.textAlign = Paint.Align.CENTER
        paint.textSize = size * 0.5f
        val bounds = Rect()
        paint.getTextBounds(letter, 0, letter.length, bounds)
        val x = size / 2f
        val y = size / 2f - bounds.centerY()
        canvas.drawText(letter, x, y, paint)
        return bitmap
    }

    private fun scaleAvatarBitmap(bitmap: Bitmap, size: Int = 384): Bitmap {
        return if (bitmap.width == size && bitmap.height == size) {
            bitmap
        } else {
            Bitmap.createScaledBitmap(bitmap, size, size, true)
        }
    }

    private fun createAdaptiveIcon(bitmap: Bitmap): IconCompat? {
        val size = bitmap.width.coerceAtMost(bitmap.height)
        if (size <= 0) return null
        val square = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(square)
        canvas.drawColor(Color.WHITE)
        val srcRect = if (bitmap.width > bitmap.height) {
            val left = (bitmap.width - bitmap.height) / 2
            Rect(left, 0, left + bitmap.height, bitmap.height)
        } else {
            val top = (bitmap.height - bitmap.width) / 2
            Rect(0, top, bitmap.width, top + bitmap.width)
        }
        val padding = (size * 0.1f).toInt()
        val dstRect = Rect(padding, padding, size - padding, size - padding)
        canvas.drawBitmap(bitmap, srcRect, dstRect, null)
        return IconCompat.createWithAdaptiveBitmap(square)
    }

    private fun parseAvatarColor(data: org.json.JSONObject): Int {
        val raw = data.opt("sender_avatar_color")
        val color = when (raw) {
            is Int -> raw
            is Long -> raw.toInt()
            is String -> raw.toIntOrNull() ?: DEFAULT_AVATAR_COLOR
            else -> DEFAULT_AVATAR_COLOR
        }
        return normalizeAvatarColor(color)
    }

    private fun normalizeAvatarColor(color: Int): Int {
        return if (color in 0x000000..0x00FFFFFF) {
            color or -0x1000000
        } else {
            color
        }
    }

    companion object {
        private const val DEFAULT_AVATAR_COLOR = -12417548
    }
}
