plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.app_historial_vehiculo"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.app_historial_vehiculo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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

// START: Add this dependencies block
dependencies {
    // Import the Firebase BoM (Bill of Materials) to manage Firebase library versions
    // The latest stable version is currently 34.0.0. Always check for the latest on Firebase docs.
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))

    // Declare the dependencies for the Firebase products you use in your app
    // When using the BoM, you do NOT specify versions here.
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    // Add any other Firebase products your app uses here (e.g., firebase-analytics, firebase-messaging)

    // Other dependencies that might already be in your project (e.g., Flutter's own dependencies)
    // For example, if you have any local project modules or other third-party Android libraries.
}
// END: Add this dependencies block