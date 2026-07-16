allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// ── file_picker 11.0.2 × AGP 9 워크어라운드 (2026-07-16, CI 실측) ──────────────
// file_picker 는 v11.0.1+ 에서 AGP 9 이상이면 KGP(org.jetbrains.kotlin.android)
// 적용을 건너뛰고 AGP '내장 Kotlin' 에 의존한다. 그런데 Flutter/AGP9 기본값
// (android.builtInKotlin=false)에선 내장 Kotlin 이 꺼져 있어 이 모듈의 Kotlin 소스가
// 전혀 컴파일되지 않고, 앱 빌드가 GeneratedPluginRegistrant 의
// 'cannot find symbol: FilePickerPlugin' 으로 실패한다(flutter build appbundle).
// → pdfx 처럼 KGP 를 모듈에 직접 적용해 준다(이미 적용돼 있으면 no-op).
//   file_picker 가 자체 수정을 배포하면 이 블록을 제거할 것.
subprojects {
    if (name == "file_picker") {
        plugins.withId("com.android.library") {
            plugins.apply("org.jetbrains.kotlin.android")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
