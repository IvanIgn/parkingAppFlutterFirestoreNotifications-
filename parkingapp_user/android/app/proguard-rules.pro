# flutter_local_notifications keep rules
-keep class com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** {
    *;
}

# GSON or TypeToken fix
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
