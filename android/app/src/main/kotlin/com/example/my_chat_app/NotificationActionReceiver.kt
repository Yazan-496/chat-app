package com.example.my_chat_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationManager
import android.util.Base64
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant

class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val extras = intent.extras
        val chatId = extras?.getString(EXTRA_CHAT_ID).orEmpty()
        val messageId = extras?.getString(EXTRA_MESSAGE_ID).orEmpty()
        val notificationId = extras?.getInt(EXTRA_NOTIFICATION_ID) ?: chatId.hashCode()
        if (chatId.isBlank()) return

        val session = readSession(context) ?: return
        val accessToken = session.optString("access_token")
        val userId = session.optJSONObject("user")?.optString("id").orEmpty()
        if (accessToken.isBlank() || userId.isBlank()) return

        val supabaseUrl = context.getString(R.string.supabase_url)
        val anonKey = context.getString(R.string.supabase_anon_key)
        if (supabaseUrl.isBlank() || anonKey.isBlank()) return

        if (action == ACTION_REPLY) {
            val reply = RemoteInput.getResultsFromIntent(intent)
                ?.getCharSequence(KEY_TEXT_REPLY)
                ?.toString()
                ?.trim()
                .orEmpty()
            if (reply.isBlank()) return
            Thread {
                val encrypted = encryptText(reply)
                val body = JSONObject()
                    .put("chat_id", chatId)
                    .put("sender_id", userId)
                    .put("content", encrypted)
                    .put("type", "TEXT")
                    .put("created_at", Instant.now().toString())
                    .put("updated_at", Instant.now().toString())
                if (messageId.isNotBlank()) {
                    body.put("reply_to_message_id", messageId)
                }
                postJson(
                    "$supabaseUrl/rest/v1/messages",
                    anonKey,
                    accessToken,
                    body,
                )
                NotificationManagerCompat.from(context).cancel(notificationId)
            }.start()
        } else if (action == ACTION_MARK_READ) {
            Thread {
                val body = JSONObject().put("p_chat", chatId)
                postJson(
                    "$supabaseUrl/rest/v1/rpc/mark_chat_read",
                    anonKey,
                    accessToken,
                    body,
                )
                NotificationManagerCompat.from(context).cancel(notificationId)
            }.start()
        }
    }

    private fun readSession(context: Context): JSONObject? {
        val prefs = context.getSharedPreferences("flutter.shared_preferences", Context.MODE_PRIVATE)
        val raw = prefs.getString("supabase_session", null) ?: return null
        return runCatching { JSONObject(raw) }.getOrNull()
    }

    private fun postJson(url: String, anonKey: String, accessToken: String, body: JSONObject): Int {
        var connection: HttpURLConnection? = null
        return try {
            val endpoint = URL(url)
            connection = endpoint.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.connectTimeout = 15000
            connection.readTimeout = 15000
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("apikey", anonKey)
            connection.setRequestProperty("Authorization", "Bearer $accessToken")
            OutputStreamWriter(connection.outputStream).use { it.write(body.toString()) }
            connection.responseCode
        } catch (_: Exception) {
            0
        } finally {
            connection?.disconnect()
        }
    }

    private fun encryptText(plainText: String): String {
        if (plainText.isEmpty()) return plainText
        val keyBytes = ENCRYPTION_KEY.toByteArray(Charsets.UTF_8)
        val textBytes = plainText.toByteArray(Charsets.UTF_8)
        val result = ByteArray(textBytes.size)
        for (i in textBytes.indices) {
            result[i] = (textBytes[i].toInt() xor keyBytes[i % keyBytes.size].toInt()).toByte()
        }
        return Base64.encodeToString(result, Base64.NO_WRAP)
    }

    companion object {
        const val ACTION_REPLY = "com.example.my_chat_app.ACTION_REPLY"
        const val ACTION_MARK_READ = "com.example.my_chat_app.ACTION_MARK_READ"
        const val EXTRA_CHAT_ID = "chat_id"
        const val EXTRA_MESSAGE_ID = "message_id"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val KEY_TEXT_REPLY = "key_text_reply"
        private const val ENCRYPTION_KEY = "MySecretKey2024"
    }
}
