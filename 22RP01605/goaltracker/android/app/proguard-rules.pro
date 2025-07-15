# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep HTTP classes for network requests
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Keep JSON classes
-keep class com.google.gson.** { *; }

# Keep notification classes
-keep class androidx.core.app.** { *; }

# Keep image picker classes
-keep class com.github.dhaval2404.** { *; }

# Keep shared preferences
-keep class androidx.preference.** { *; }

# Keep multidex
-keep class androidx.multidex.** { *; }

# Keep URL launcher
-keep class androidx.browser.** { *; }

# Keep file picker
-keep class com.mr.flutter.** { *; }

# Keep path provider
-keep class androidx.core.content.** { *; }

# Keep mailer
-keep class javax.mail.** { *; }
-keep class com.sun.mail.** { *; }

# Keep intl
-keep class com.ibm.icu.** { *; }

# Keep cloud functions
-keep class com.google.cloud.** { *; }

# Keep HTTP client
-keep class org.apache.http.** { *; }

# Keep URL launcher
-keep class android.content.Intent { *; }
-keep class android.net.Uri { *; } 