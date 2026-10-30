#!/usr/bin/env python3
"""Install a fixed debug.keystore so every CI APK shares the same signature."""
import base64
import os
from pathlib import Path

B64 = Path("signing/debug.keystore.b64")


def main() -> None:
    if not B64.exists():
        raise SystemExit("missing signing/debug.keystore.b64")

    android_dir = Path.home() / ".android"
    android_dir.mkdir(parents=True, exist_ok=True)
    dest = android_dir / "debug.keystore"
    dest.write_bytes(base64.b64decode(B64.read_text().strip()))
    print(f"installed {dest} ({dest.stat().st_size} bytes)")

    # Flutter release without custom signingConfig uses debug keystore
    print("ANDROID_HOME/user debug keystore ready for consistent signature")


if __name__ == "__main__":
    main()
