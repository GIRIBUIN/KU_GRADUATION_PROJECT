"""Used only by the manually dispatched, protected TestFlight workflow on macOS.

Signing material comes from GitHub environment secrets and stays in the ephemeral runner.
No certificate/key value is printed or placed in the repository/build artifact.
"""
import base64
from datetime import datetime, timezone
import os
from pathlib import Path
import plistlib
import re
import secrets
import shutil
import subprocess
import sys

required = ["APPLE_CERTIFICATE_P12_BASE64", "APPLE_CERTIFICATE_PASSWORD", "IOS_APP_PROFILE_BASE64",
            "IOS_WIDGET_PROFILE_BASE64", "APPLE_TEAM_ID", "IOS_BUNDLE_ID", "IOS_APP_GROUP",
            "APP_STORE_CONNECT_KEY_ID", "APP_STORE_CONNECT_ISSUER_ID", "APP_STORE_CONNECT_PRIVATE_KEY"]
missing = [key for key in required if not os.environ.get(key)]
if missing:
    raise SystemExit("Missing signing secrets: " + ", ".join(missing))
if sys.platform != "darwin" or not os.environ.get("RUNNER_TEMP"):
    raise SystemExit("Run only in the macOS CI signing job")
temporary = Path(os.environ["RUNNER_TEMP"]) / "ku-todo-signing"
temporary.mkdir(exist_ok=True)
team = os.environ["APPLE_TEAM_ID"]
bundle = os.environ["IOS_BUNDLE_ID"]
group = os.environ["IOS_APP_GROUP"]
if not re.fullmatch(r"[A-Z0-9]{10}", team) or not re.fullmatch(r"[A-Za-z0-9.-]+", bundle + group):
    raise SystemExit("Invalid Apple identifiers")

def run(*command):
    result = subprocess.run(command, capture_output=True)
    if result.returncode != 0:
        # Never include a command line containing a password in a traceback.
        raise SystemExit(f"{command[0]} failed during signing setup; check the signing environment.")
    return result

if sys.argv[1] == "prepare":
    profile_ids = {}
    directory = Path.home() / "Library/MobileDevice/Provisioning Profiles"
    directory.mkdir(parents=True, exist_ok=True)
    for kind, identifier in [("APP", bundle), ("WIDGET", bundle + ".widgets")]:
        profile = temporary / f"{kind}.mobileprovision"
        profile.write_bytes(base64.b64decode(os.environ[f"IOS_{kind}_PROFILE_BASE64"]))
        decoded = plistlib.loads(run("security", "cms", "-D", "-i", str(profile)).stdout)
        entitlements = decoded["Entitlements"]
        if team not in decoded["TeamIdentifier"] or entitlements["application-identifier"].split(".", 1)[-1] != identifier:
            raise SystemExit(f"{kind} profile does not match the app bundle and team")
        if group not in entitlements.get("com.apple.security.application-groups", []):
            raise SystemExit(f"{kind} profile must include the widget App Group")
        if decoded["ExpirationDate"].replace(tzinfo=timezone.utc) <= datetime.now(timezone.utc):
            raise SystemExit(f"{kind} profile expired")
        uuid = decoded["UUID"]
        if not re.fullmatch(r"[a-fA-F0-9-]{36}", uuid):
            raise SystemExit("Invalid profile UUID")
        shutil.copy2(profile, directory / f"{uuid}.mobileprovision")
        profile_ids[identifier] = uuid
    certificate = temporary / "distribution.p12"
    certificate.write_bytes(base64.b64decode(os.environ["APPLE_CERTIFICATE_P12_BASE64"]))
    certificate.chmod(0o600)
    keychain = str(temporary / "signing.keychain-db")
    password = secrets.token_urlsafe(32)
    run("security", "create-keychain", "-p", password, keychain)
    run("security", "set-keychain-settings", "-lut", "21600", keychain)
    run("security", "unlock-keychain", "-p", password, keychain)
    run("security", "import", str(certificate), "-P", os.environ["APPLE_CERTIFICATE_PASSWORD"], "-A", "-t", "cert", "-f", "pkcs12", "-k", keychain)
    run("security", "set-key-partition-list", "-S", "apple-tool:,apple:,codesign:", "-s", "-k", password, keychain)
    run("security", "list-keychains", "-d", "user", "-s", keychain)
    options = {"method": "app-store-connect", "teamID": team, "signingStyle": "manual",
               "provisioningProfiles": profile_ids, "uploadSymbols": True, "manageAppVersionAndBuildNumber": False}
    export = temporary / "ExportOptions.plist"
    export.write_bytes(plistlib.dumps(options))
    values = {"APPLE_DEVELOPMENT_TEAM": team, "KU_BUNDLE_ID": bundle, "KU_APP_GROUP": group,
              "IOS_APP_PROFILE_UUID": profile_ids[bundle], "IOS_WIDGET_PROFILE_UUID": profile_ids[bundle + ".widgets"],
              "KU_BUILD_NUMBER": os.environ["GITHUB_RUN_NUMBER"], "KU_EXPORT_OPTIONS": str(export)}
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as env:
        for key, value in values.items():
            env.write(f"{key}={value}\n")
    print("Validated app/widget profiles and prepared temporary signing keychain.")
elif sys.argv[1] == "upload":
    archives = list(Path("build/ios/ipa").glob("*.ipa"))
    if len(archives) != 1:
        raise SystemExit("Expected one signed IPA")
    key_id = os.environ["APP_STORE_CONNECT_KEY_ID"]
    if not re.fullmatch(r"[A-Z0-9]+", key_id):
        raise SystemExit("Invalid API key ID")
    keys = Path.home() / ".appstoreconnect/private_keys"
    keys.mkdir(parents=True, exist_ok=True)
    key = keys / f"AuthKey_{key_id}.p8"
    key.write_text(os.environ["APP_STORE_CONNECT_PRIVATE_KEY"], encoding="utf-8")
    key.chmod(0o600)
    subprocess.run(["xcrun", "altool", "--upload-app", "--type", "ios", "-f", str(archives[0]),
                    "--apiKey", key_id, "--apiIssuer", os.environ["APP_STORE_CONNECT_ISSUER_ID"]], check=True)
else:
    raise SystemExit("Expected prepare or upload")
