plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.edumanage"
    compileSdk = 33 // or use flutter.compileSdkVersion if defined elsewhere
    ndkVersion = "your-ndk-version-if-needed" // optional, or remove if unused

    defaultConfig {
        applicationId = "com.example.edumanage"
        minSdk = 23 // Updated to meet Firebase Auth requirements
        targetSdk = 33 // or your target SDK version
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            // Replace with your signing config for release or debug signing for testing
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false // set true if using proguard
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
