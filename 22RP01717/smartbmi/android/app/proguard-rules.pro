# ========== Flutter Plugin Rules ==========
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ========== flutter_local_notifications ==========
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ========== Firebase ==========
-keep class io.flutter.plugins.firebase.core.** { *; }
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class io.flutter.plugins.firebase.firestore.** { *; }

# ========== path_provider ==========
-keep class io.flutter.plugins.pathprovider.** { *; }

# ========== General Firebase Keep Rules ==========
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
