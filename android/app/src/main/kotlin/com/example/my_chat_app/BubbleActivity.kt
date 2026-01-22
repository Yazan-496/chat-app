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
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                putExtra("chat_id", chatId)
                putExtra("chatid", chatId)
                putExtra("from_bubble", true)
                // Use SINGLE_TOP to reuse existing activity if possible, or create new one in THIS task
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
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
