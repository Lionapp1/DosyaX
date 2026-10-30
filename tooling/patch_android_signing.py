#!/usr/bin/env python3
"""Fixed keystore + explicit release/debug signing so every APK shares one signature."""
import base64
import re
from pathlib import Path

B64 = Path("signing/debug.keystore.b64")
GRADLE = Path("android/app/build.gradle.kts")


def main() -> None:
    if not B64.exists():
        raise SystemExit("missing signing/debug.keystore.b64")

    android_dir = Path.home() / ".android"
    android_dir.mkdir(parents=True, exist_ok=True)
    dest = android_dir / "debug.keystore"
    dest.write_bytes(base64.b64decode(B64.read_text().strip()))
    print(f"installed {dest} ({dest.stat().st_size} bytes)")

    if not GRADLE.exists():
        raise SystemExit("missing android/app/build.gradle.kts")

    t = GRADLE.read_text()

    # Stable applicationId — new id avoids conflict with old broken installs
    t = re.sub(
        r'applicationId\s*=\s*"[^"]+"',
        'applicationId = "com.dosyax.app"',
        t,
        count=1,
    )
    t = re.sub(
        r'namespace\s*=\s*"[^"]+"',
        'namespace = "com.dosyax.app"',
        t,
        count=1,
    )

    if "signingConfigs" not in t:
        signing_block = '''
    signingConfigs {
        create("stable") {
            storeFile = file(System.getProperty("user.home") + "/.android/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }
'''
        # insert inside android { after defaultConfig block start area
        t = t.replace("android {", "android {" + signing_block, 1)

    # Force release + debug to use stable config
    if 'signingConfig = signingConfigs.getByName("stable")' not in t:
        t = re.sub(
            r"(release\s*\{)",
            r'\1\n            signingConfig = signingConfigs.getByName("stable")',
            t,
            count=1,
        )
        if "getByName(\"debug\")" in t or re.search(r"debug\s*\{", t):
            t = re.sub(
                r"(debug\s*\{)",
                r'\1\n            signingConfig = signingConfigs.getByName("stable")',
                t,
                count=1,
            )

    GRADLE.write_text(t)
    print("gradle signing + applicationId com.dosyax.app patched")


if __name__ == "__main__":
    main()
