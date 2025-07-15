plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("../key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "com.example.health"
    compileSdk = flutter.compileSdkVersion

    // ✅ Updated to required NDK version
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
        freeCompilerArgs += listOf(
            "-Xno-incremental",
            "-Xno-call-assertions", 
            "-Xno-receiver-assertions",
            "-Xno-param-assertions",
            "-Xno-type-assertions",
            "-Xno-optimized-callable-references",
            "-Xno-builtin-extension-functions"
        )
    }

    defaultConfig {
        applicationId = "com.example.health"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Only apply signing config if keystore properties are available
            if (keystoreProperties.containsKey("storePassword") && 
                keystoreProperties.containsKey("keyAlias") && 
                keystoreProperties.containsKey("keyPassword")) {
                signingConfig = signingConfigs.create("release").apply {
                    storeFile = file("../" + (keystoreProperties["keyPath"] ?: "upload-keystore.jks"))
                    storePassword = keystoreProperties["storePassword"] as String?
                    keyAlias = keystoreProperties["keyAlias"] as String?
                    keyPassword = keystoreProperties["keyPassword"] as String?
                }
            }
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}

// Completely disable incremental compilation and caching
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions {
        freeCompilerArgs += listOf(
            "-Xno-incremental", 
            "-Xno-call-assertions", 
            "-Xno-receiver-assertions",
            "-Xno-param-assertions",
            "-Xno-type-assertions",
            "-Xno-optimized-callable-references",
            "-Xno-builtin-extension-functions"
        )
    }
    outputs.cacheIf { false }
    outputs.upToDateWhen { false }
}

// Force clean build for all tasks
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    outputs.cacheIf { false }
    outputs.upToDateWhen { false }
}

