# my_chat_app

A new Flutter project.

## FCM testing (quick examples)


- Basic notification (shows system default sound when app is backgrounded/killed):

	- Android / iOS notification payload (JSON):

		{
			"notification": {
				"title": "Alice",
				"body": "Hey — are you free to chat?"
			},
			"data": {
				"screen": "chat",
				"chatId": "chat_123"
			},
			"to": "<FCM_DEVICE_TOKEN>"
		}

- Data-only message (recommended when you want the app to handle notification presentation yourself). Background isolate will persist and main isolate will show notification on resume:

		{
			"data": {
				"type": "message",
				"title": "Alice",
				"body": "Sent you a photo",
				"chatId": "chat_123"
			},
			"to": "<FCM_DEVICE_TOKEN>"
		}

Notes:
- The app intentionally uses the platform default notification sound. If you need a custom sound, add that asset, list it in `pubspec.yaml`, and configure `NotificationService` to reference it (you'll also need to recreate the Android channel after changing sound settings).
- For background reliability on Android, prefer using notification messages when the app should display notifications while killed. Data-only messages are useful when the app itself wants to control presentation.
