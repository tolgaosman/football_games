# ProGuard / R8 keep rules for Flyball (release builds).
#
# R8 here shrinks and obfuscates the Java/Kotlin (native Android) layer only.
# The Dart code is AOT-compiled and is obfuscated separately via
#   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols

# --- Flutter engine ---------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# --- sqflite (SQLite plugin) ------------------------------------------------
# The plugin is reflected into from the engine; keep its entry points.
-keep class com.tekartik.sqflite.** { *; }

# --- Kotlin runtime ---------------------------------------------------------
-dontwarn kotlin.**
-dontwarn kotlinx.**

# --- General safety: keep annotations & native method names -----------------
-keepattributes *Annotation*
-keepattributes Signature
-keepclasseswithmembernames class * {
    native <methods>;
}
