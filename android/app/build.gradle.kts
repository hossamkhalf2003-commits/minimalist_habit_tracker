plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.minimalist_habit_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Fix for notifications: Enable Java 8+ features
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.minimalist_habit_tracker"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        
        // Use the values provided directly by the Flutter plugin
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Required for desugaring
        multiDexEnabled = true 
    }

    buildTypes {
        release {
            // In Kotlin DSL, we use 'is...' properties
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Correct Kotlin syntax for adding the desugaring dependency
    add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.0.4")
}