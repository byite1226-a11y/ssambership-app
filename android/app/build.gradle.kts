import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 릴리즈 서명(P0-5): android/key.properties 가 있으면 release 키로 서명하고,
// 없으면 debug 서명으로 폴백해 빌드가 깨지지 않는다(로컬·CI 겸용).
// key.properties 생성 절차·보관 수칙: docs/PLAY_STORE_REVIEW_PLAN.md 참고.
// ★ keystore·비밀번호는 절대 커밋 금지(android/.gitignore 가 차단).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.ssambership.app"
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
        applicationId = "com.ssambership.app"
        // 명시 고정(P0-6). minSdk 24 = Flutter 3.44 기본(Android 7.0).
        minSdk = 24
        targetSdk = 36
        // versionCode/Name 은 pubspec.yaml 의 version(x.y.z+N)에서 온다 —
        // 스토어 업로드마다 +N 을 반드시 증가(규약: HANDOFF §3-1-B).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties 존재 시 release 키, 없으면 debug 폴백(빌드 유지).
            // ★ 스토어 업로드 전 반드시 release 키 서명인지 확인할 것.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
