package com.example.my_chat_app

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class BubbleActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val chatId = intent.getStringExtra("chat_id") ?: intent.getStringExtra("chatid") ?: ""

        if (chatId.isNotEmpty()) {
            val flutterIntent = Intent(this, MainActivity::class.java).apply {
                putExtra("chat_id", chatId)
                putExtra("chatid", chatId)
                putExtra("from_bubble", true)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            }
            startActivity(flutterIntent)
            overridePendingTransition(0, 0)
        }

        finish()
        overridePendingTransition(0, 0)
    }

    override fun onBackPressed() {
        super.onBackPressed()
    }
}
