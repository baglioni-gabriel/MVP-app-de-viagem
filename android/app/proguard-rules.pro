# Flutter-specific ProGuard rules

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }

# Keep model classes that are serialized/deserialized
-keepattributes *Annotation*
-keepattributes Signature

# Prevent R8 from stripping interfaces used by Gson/JSON
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
