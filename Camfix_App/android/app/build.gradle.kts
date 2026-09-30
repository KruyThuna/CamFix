plugins {
    id("com.android.application")

    // AGP 9+ has built-in Kotlin support.
    // Do NOT add:
    // id("org.jetbrains.kotlin.android")

    id("dev.flutter.flutter-gradle-plugin")
}

// google_maps_flutter needs the Maps key in the manifest at build time.
// Put MAPS_API_KEY=... in android/local.properties.
val mapsApiKey: String = rootProject.file("local.properties")
    .takeIf { it.exists() }
    ?.readLines()
    ?.firstOrNull { it.trimStart().startsWith("MAPS_API_KEY=") }
    ?.substringAfter("=")
    ?.trim()
    ?: ""

android {
    namespace = "com.example.camfix_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.camfix_app"

        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
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