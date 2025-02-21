# Keep ZegoCloud-related classes
-keep class **.zego.** { *; }
-keep class im.zego.** { *; }
-keep class com.zegocloud.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
# Vendor-Specific Push Services
# Uncomment these if you need push notifications for the corresponding vendors
# Remove any rules for vendors you are not targeting.
-keep class com.heytap.msp.** { *; }
-keep class com.huawei.hms.** { *; }
-keep class com.vivo.push.** { *; }
-keep class com.xiaomi.mipush.sdk.** { *; }

# Conscrypt (for secure connections)
-keep class org.conscrypt.** { *; }

# XML Parsing and SAX Support
-keep class org.xmlpull.** { *; }
-keep class org.xml.sax.** { *; }
-keep class org.w3c.dom.bootstrap.** { *; }

# Suppress warnings for unused vendor classes
-dontwarn com.heytap.**
-dontwarn com.huawei.**
-dontwarn com.vivo.**
-dontwarn com.xiaomi.**
-dontwarn okhttp3.internal.platform.ConscryptPlatform
-dontwarn okhttp3.internal.platform.Android10Platform

# Jackson JSON parser classes
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes Signature
-keepattributes Exceptions
-keep class com.fasterxml.jackson.** { *; }
-keepnames class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.databind.**
