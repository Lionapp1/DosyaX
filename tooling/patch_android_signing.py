#!/usr/bin/env python3
"""Write android/app/build.gradle.kts with release signing (AGP 9 safe)."""
import base64
from pathlib import Path

GRADLE = Path("android/app/build.gradle.kts")
KEY_PROPS = Path("android/key.properties")
JKS = Path("android/app/dosyax-release.jks")
B64 = Path("signing/keystore.b64")

# plugins {} MUST be first for new AGP
CONTENT = r'''plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.lionapp1.dosyax"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
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

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
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
