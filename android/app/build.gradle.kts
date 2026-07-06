plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ssambership.ssambership_app"
    // 명시 고정(P0-6): Google Play 신규 앱 요건 = 2026-08-31부터 targetSdk 36
    // (Android 16) 이상. Flutter 3.44.4 기본값과 동일 값을 위임 대신 고정해
    // SDK 업그레이드가 조용히 타깃을 바꾸지 못하게 한다.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ssambership.ssambership_app"
        // 명시 고정(P0-6). minSdk 24 = Flutter 3.44 기본(Android 7.0).
        minSdk = 24
        targetSdk = 36
        // versionCode/Name 은 pubspec.yaml 의 version(x.y.z+N)에서 온다 —
        // 스토어 업로드마다 +N 을 반드시 증가(규약: HANDOFF §3-1-B).
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
