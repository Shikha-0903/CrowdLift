# Ignore missing proguard.annotation.Keep and KeepClassMembers annotations
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Razorpay classes should be kept
-keep class com.razorpay.** { *; }
