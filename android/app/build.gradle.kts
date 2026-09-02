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

    buildTypes {
        release {
            // 💡 Asignamos la firma por defecto de debug para esquivar el error de instalación
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // ✅ TU BLOQUE RECUPERADO PARA RENOMBRAR EL APK AUTOMÁTICAMENTE
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