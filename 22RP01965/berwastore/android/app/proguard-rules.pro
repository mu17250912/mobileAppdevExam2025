# Stripe SDK keep rules
-keep class com.stripe.** { *; }
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.stripe.**
-dontwarn com.reactnativestripesdk.**

# Stripe push provisioning keep rules
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; } 