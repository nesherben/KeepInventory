plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.keepinventory"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.keepinventory"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("../key.jks")
            storePassword = "" // Pon tus contraseñas si vas a firmar
            keyAlias = "key"
            keyPassword = ""
        }
    }

    buildTypes {
        release {
            // 💡 RECUERDA: Si quieres la release SIN FIRMAR como hablamos antes, 
            // cambia esta línea a: signingConfig = null
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // ✅ BLOQUE CORREGIDO PARA RENOMBRAR EL APK AUTOMÁTICAMENTE
    applicationVariants.all {
        val variantName = name
        outputs.all {
            val outputImpl = this as? com.android.build.gradle.internal.api.ApkVariantOutputImpl
            if (outputImpl != null) {
                // Usa flutter.versionName directamente
                outputImpl.outputFileName = "KeepInventory-v${flutter.versionName}-${variantName}.apk"
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}