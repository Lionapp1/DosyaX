#!/usr/bin/env python3
from pathlib import Path

MANIFEST = Path("android/app/src/main/AndroidManifest.xml")

PERMS = [
    '    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />',
    '    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />',
    '    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />',
    '    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />',
    '    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />',
    '    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />',
]


def main() -> None:
    t = MANIFEST.read_text()
    # Ensure tools namespace for ignore attributes if needed
    if "xmlns:tools" not in t:
        t = t.replace(
            "<manifest",
            '<manifest xmlns:tools="http://schemas.android.com/tools"',
            1,
        )

    t = t.replace('android:label="dosyax"', 'android:label="DosyaX"')

    if "MANAGE_EXTERNAL_STORAGE" not in t:
        insert = "\n".join(PERMS) + "\n"
        lines = t.splitlines(keepends=True)
        out = []
        done = False
        for line in lines:
            out.append(line)
            if not done and "<manifest" in line:
                out.append(insert)
                done = True
        t = "".join(out)

    if "requestLegacyExternalStorage" not in t:
        t = t.replace(
            "<application",
            '<application android:requestLegacyExternalStorage="true"',
            1,
        )

    # PreserveExternalStorage helps some OEM file managers
    if "preserveLegacyExternalStorage" not in t:
        t = t.replace(
            'android:requestLegacyExternalStorage="true"',
            'android:requestLegacyExternalStorage="true" android:preserveLegacyExternalStorage="true"',
            1,
        )

    MANIFEST.write_text(t)

    values = Path("android/app/src/main/res/values")
    drawable = Path("android/app/src/main/res/drawable")
    mipmap = Path("android/app/src/main/res/mipmap-anydpi-v26")
    values.mkdir(parents=True, exist_ok=True)
    drawable.mkdir(parents=True, exist_ok=True)
    mipmap.mkdir(parents=True, exist_ok=True)

    (values / "ic_launcher_colors.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#1D4ED8</color>
</resources>
"""
    )
    (drawable / "ic_launcher_foreground.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#FFFFFF" android:pathData="M30,34h48a4,4 0 0,1 4,4v8H26v-8a4,4 0 0,1 4,-4z"/>
    <path android:fillColor="#93C5FD" android:pathData="M26,50h56v28a6,6 0 0,1 -6,6H32a6,6 0 0,1 -6,-6z"/>
    <path android:fillColor="#FBBF24" android:pathData="M40,62h28v6H40z"/>
    <path android:fillColor="#FBBF24" android:pathData="M40,72h18v6H40z"/>
</vector>
"""
    )
    (mipmap / "ic_launcher.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""
    )
    print("manifest + icon patched")


if __name__ == "__main__":
    main()
