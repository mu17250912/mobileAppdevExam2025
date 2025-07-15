plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import com.android.build.gradle.internal.api.ApkVariantOutputImpl

android {
    namespace = "com.example.saferide"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.saferide"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex for large apps
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Disable all optimization for now to ensure build completes
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Disable proguard for now
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        debug {
            // Enable debugging
            isDebuggable = true
        }
    }

    // Remove the APK output name override that might be causing issues
    // applicationVariants.all {
    //     outputs.all {
    //         if (this is ApkVariantOutputImpl) {
    //             this.outputFileName = "app-release.apk"
    //         }
    //     }
    // }
    
    // Enable R8 optimization
    buildFeatures {
        buildConfig = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for Java 8+ features
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Multidex support for large apps
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Google Sign-In dependencies
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    implementation("com.google.firebase:firebase-auth:22.3.1")
}
