plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.keepinventory"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Asegúrate de mantener tu applicationId original si era distinto
        applicationId = "com.example.keepinventory" 
        minSdk = flutter.minSdkVersion // Listo para SQLite
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        release {
            if (project.hasProperty('myStoreFile')) {
                storeFile file(myStoreFile)
                storePassword myStorePassword
                keyAlias myKeyAlias
                keyPassword myKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Asignamos la firma release aquí
            signingConfig signingConfigs.release
            minifyEnabled true // Opcional: ofuscar y reducir código
            shrinkResources true // Opcional
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
