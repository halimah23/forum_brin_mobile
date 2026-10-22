# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# SharedPreferences and FilePicker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Supabase / Netty / Coroutines / Gson
-dontwarn io.flutter.embedding.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-ignorewarnings
