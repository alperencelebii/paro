plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingProperty(name: String): String? =
    keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }

val hasReleaseKeystore =
    keystorePropertiesFile.exists() &&
    signingProperty("storeFile") != null &&
    signingProperty("storePassword") != null &&
    signingProperty("keyAlias") != null &&
    signingProperty("keyPassword") != null

android {
    namespace = "com.glowuply.paro"
    compileSdk = 36
    ndkVersion = "29.0.13846066"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.glowuply.paro"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable MultiDex to support apps with more than 64K methods.
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = signingProperty("keyAlias")
                keyPassword = signingProperty("keyPassword")
                storeFile = file(signingProperty("storeFile")!!)
                storePassword = signingProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            // If android/key.properties is not available, release builds fall back
            // to the debug keystore so local APK generation still works.
            // Use a real upload keystore before publishing to Google Play.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // MultiDex support for apps with more than 64K methods
    implementation("androidx.multidex:multidex:2.0.1")

    // Firebase Crashlytics (optional)
    // implementation("com.google.firebase:firebase-crashlytics")

    // Play Core Services
    implementation("com.google.android.play:app-update:2.1.0")
    implementation("com.google.android.play:review:2.0.1")

    // Google Play Billing
    val billingVersion = "8.0.0"
    implementation("com.android.billingclient:billing:$billingVersion")

    // WorkManager (fix for Play Core issues)
    implementation("androidx.work:work-runtime-ktx:2.8.1")

    // Google Sign-In & Firebase Auth
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    implementation("com.google.firebase:firebase-auth:22.3.0")
}
