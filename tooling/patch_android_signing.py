#!/usr/bin/env python3
"""Configure release signing in android/app/build.gradle.kts after flutter create."""
from pathlib import Path

GRADLE = Path("android/app/build.gradle.kts")
KEY_PROPS = Path("android/key.properties")
JKS = Path("android/app/dosyax-release.jks")
B64 = Path("signing/keystore.b64")


def main() -> None:
    if not B64.exists():
        raise SystemExit("missing signing/keystore.b64")

    import base64

    JKS.write_bytes(base64.b64decode(B64.read_text().strip()))
    KEY_PROPS.write_text(
        "storePassword=dosyax_store_2026\n"
        "keyPassword=dosyax_store_2026\n"
        "keyAlias=dosyax\n"
        "storeFile=dosyax-release.jks\n"
    )

    t = GRADLE.read_text()
    if "key.properties" in t and "signingConfigs" in t:
        print("already patched")
        return

    header = """
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

"""

    if not t.lstrip().startswith("import java.util.Properties"):
        t = header + t

    # Inject signingConfigs before buildTypes
    if "signingConfigs" not in t:
        signing = """
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
"""
        t = t.replace("    buildTypes {", signing + "\n    buildTypes {", 1)

    # Ensure release uses signingConfig
    if 'signingConfig = signingConfigs.getByName("release")' not in t:
        # Flutter template often has:
        # release {
        #     // Signing with the debug keys for now...
        # }
        t = t.replace(
            "        release {",
            "        release {\n            signingConfig = signingConfigs.getByName(\"release\")",
            1,
        )

    GRADLE.write_text(t)
    print("signing configured")
    print(GRADLE.read_text())


if __name__ == "__main__":
    main()
