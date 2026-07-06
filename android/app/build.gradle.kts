plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase / Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.app_inventario_ventas"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.app_inventario_ventas"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
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

    applicationVariants.all {
        val variant = this
        variant.outputs.all {
            val output = this as? com.android.build.gradle.api.ApkVariantOutput
            if (output != null) {
                val abi = output.filters.find { it.filterType == "ABI" }?.identifier
                if (abi != null) {
                    output.outputFileName = "Pymevision-$abi.apk"
                } else {
                    output.outputFileName = "Pymevision.apk"
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

tasks.register("copyRenamedApks") {
    doLast {
        val flutterApkDir = file("../../build/app/outputs/flutter-apk")
        val apkReleaseDir = file("../../build/app/outputs/apk/release")
        if (apkReleaseDir.exists()) {
            apkReleaseDir.listFiles()?.forEach { file ->
                if (file.name.startsWith("Pymevision") && file.name.endsWith(".apk")) {
                    file.copyTo(File(flutterApkDir, file.name), overwrite = true)
                    println("Copiado APK renombrado a: ${file.name} en flutter-apk")
                }
            }
        }
    }
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy("copyRenamedApks")
}
