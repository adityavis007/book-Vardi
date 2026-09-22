# Flutter ProGuard Rules

# Google Play Core & Deferred Components (Resolves R8 missing class errors)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn io.flutter.embedding.android.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Geolocation & Geocoding SDK Rules
-dontwarn com.baseflow.geolocator.**
-dontwarn com.baseflow.geocoding.**

# Razorpay SDK Rules
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/
-keepclasseswithmembers class * {
    public void onPaymentSuccess(java.lang.String);
    public void onPaymentError(int, java.lang.String);
}

# Firebase Suite Rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Flutter Wrapper Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
