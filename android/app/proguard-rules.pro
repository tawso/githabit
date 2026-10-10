# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Prevent obfuscation of Flutter engine classes
-dontwarn io.flutter.**

# Hive rules
-keep class io.github.hivedb.** { *; }
-dontwarn io.github.hivedb.**

# OkHttp & Dio
-dontwarn okhttp3.**
-dontwarn okio.**
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

