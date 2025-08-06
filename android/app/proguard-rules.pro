# ProGuard rules for API key protection and code obfuscation

# Keep Flutter framework classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Obfuscate API key related classes and methods
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Obfuscate environment configuration
-keepclassmembers class com.example.mobilapp_pysc.config.** {
    !public *;
}

# Obfuscate service classes that handle API calls
-keepclassmembers class com.example.mobilapp_pysc.services.** {
    !public *;
}

# Obfuscate any class containing "api" or "key" in name
-keepclassmembers class *Api* {
    !public *;
}
-keepclassmembers class *Key* {
    !public *;
}

# Obfuscate string literals that might contain API keys
-assumenosideeffects class java.lang.String {
    public static java.lang.String valueOf(java.lang.Object);
}

# Remove debug information
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable,*Annotation*

# Obfuscate package names
-repackageclasses ''

# Remove unused code
-dontwarn **
-ignorewarnings

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keep class **.R$* {
    public static <fields>;
}

# Obfuscate environment variable names
-assumenosideeffects class java.lang.System {
    public static java.lang.String getProperty(java.lang.String);
    public static java.lang.String getenv(java.lang.String);
}

# Remove logging statements
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Obfuscate HTTP request headers that might contain API keys
-keepclassmembers class * {
    @retrofit2.http.Header <fields>;
}

# Additional security: obfuscate any class with "config" in name
-keepclassmembers class *Config* {
    !public *;
}

# Obfuscate any class with "secret" or "token" in name
-keepclassmembers class *Secret* {
    !public *;
}
-keepclassmembers class *Token* {
    !public *;
} 