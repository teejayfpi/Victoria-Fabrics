# Victoria Fabrics — release ProGuard/R8 rules.
#
# Flutter embeds its own keep rules; these cover the plugins we depend on
# that rely on reflection, plus a couple of safe generalisations.

# ─── Firebase / Google Play services ────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ─── Cloud Firestore model classes ──────────────────────────────────────
# Firestore deserialises documents reflectively; keep our data models.
-keepclassmembers class com.fabrichaven.fabric_haven.** {
    <init>(...);
    <fields>;
}
-keep class com.fabrichaven.fabric_haven.** { *; }

# ─── image_picker / androidx ────────────────────────────────────────────
-dontwarn androidx.**

# ─── JSON / annotations ─────────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
