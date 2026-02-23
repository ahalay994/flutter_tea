plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tea_multitenant"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.tea_multitenant"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Получаем APP_NAME из .env файла
        val envFile = File(rootProject.projectDir, ".env")
        var appName = "Turbo Tea Multi-Tenant" // Значение по умолчанию
        if (envFile.exists()) {
            val envContents = envFile.readLines()
            val appNameLine = envContents.find { it.startsWith("APP_NAME=") }
            if (appNameLine != null) {
                appName = appNameLine.substringAfter("=").trim()
                // Убираем кавычки, если они есть
                if (appName.startsWith("\"") && appName.endsWith("\"")) {
                    appName = appName.substring(1, appName.length - 1)
                } else if (appName.startsWith("'") && appName.endsWith("'")) {
                    appName = appName.substring(1, appName.length - 1)
                }
            }
        }
        manifestPlaceholders["appName"] = appName
    }
    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
