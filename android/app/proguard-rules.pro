# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Background Service
-keep class id.flutter.flutter_background_service.** { *; }
-dontwarn id.flutter.flutter_background_service.**
-keep public class * extends android.app.Service

# Keep all app classes to prevent entry point removal
-keep class com.example.my_chat_app.** { *; }

# Prevent removing the entry point function
-keepnames class * {
    void onStart(id.flutter.flutter_background_service.ServiceInstance);
}

# Ignore warnings for Google Play Store SplitCompat (used for dynamic features)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
