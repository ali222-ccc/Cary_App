plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cary.apps"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // إعدادات التوقيع المباشرة لإنهاء مشكلة الكلام الأحمر في المتجر
    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "123654"
            storeFile = file("upload-keystore.jks")
            storePassword = "123654"
            
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.cary.apps"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // هذا السطر هو ما يحول ملفك من Debug إلى Release مقبول في المتجر
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}