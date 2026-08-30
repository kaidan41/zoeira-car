# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# In-App Purchase
-keep class com.android.billingclient.** { *; }

# Mantém classes de modelo para Firestore
-keep class com.zoeiracartv.app.** { *; }

# Evita remover classes usadas por reflexão
-keepattributes Signature
-keepattributes *Annotation*

# Play Core (deferred components do Flutter) — não utilizado neste app
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# BackEvent é API 34+ (referenciado pelo FlutterView); ausente em API < 34.
# O app não usa back gesture nativo — só não deixe o R8 cair nisso.
-dontwarn android.window.BackEvent
