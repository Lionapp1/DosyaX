#!/usr/bin/env python3
"""Write a complete android/app/build.gradle.kts with release signing."""
import base64
from pathlib import Path

GRADLE = Path("android/app/build.gradle.kts")
KEY_PROPS = Path("android/key.properties")
JKS = Path("android/app/dosyax-release.jks")
B64 = Path("signing/keystore.b64")

CONTENT = r'''import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.lionapp1.dosyax"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.lionapp1.dosyax"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
'''


def main() -> None:
    if not B64.exists():
        raise SystemExit("missing signing/keystore.b64")

    JKS.write_bytes(base64.b64decode(B64.read_text().strip()))
    KEY_PROPS.write_text(
        "storePassword=dosyax_store_2026\n"
        "keyPassword=dosyax_store_2026\n"
        "keyAlias=dosyax\n"
        "storeFile=dosyax-release.jks\n"
    )
    GRADLE.write_text(CONTENT)
    print("wrote signed build.gradle.kts")


if __name__ == "__main__":
    main()
