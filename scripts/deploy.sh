#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-}"
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
  echo "Usage: bash scripts/deploy.sh <staging|production>" >&2
  exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/config/$ENVIRONMENT.json"

cd "$ROOT_DIR"

for command_name in flutter firebase python3; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
done

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Configuration file not found: $CONFIG_FILE" >&2
  echo "Copy config/$ENVIRONMENT.example.json to config/$ENVIRONMENT.json and fill in the Firebase Web app values." >&2
  exit 1
fi

CONFIG_VALUES="$(python3 - "$CONFIG_FILE" "$ENVIRONMENT" <<'PY'
import json
import sys

path, expected_environment = sys.argv[1:3]
with open(path, encoding="utf-8") as config_file:
    config = json.load(config_file)

required = (
    "APP_ENV",
    "SEND_EMAIL_VERIFICATION",
    "FIREBASE_API_KEY",
    "FIREBASE_APP_ID",
    "FIREBASE_MESSAGING_SENDER_ID",
    "FIREBASE_PROJECT_ID",
)
missing = [key for key in required if not isinstance(config.get(key), str) or not config[key].strip()]
if missing:
    raise SystemExit("Missing or empty configuration values: " + ", ".join(missing))

if config["APP_ENV"] != expected_environment:
    raise SystemExit(
        f"APP_ENV must be '{expected_environment}', got '{config['APP_ENV']}'."
    )

if config["SEND_EMAIL_VERIFICATION"] not in ("true", "false"):
    raise SystemExit("SEND_EMAIL_VERIFICATION must be the string 'true' or 'false'.")

for key in required:
    value = config[key].strip().lower()
    if value.startswith("replace-with-") or value in ("your-api-key", "your-app-id"):
        raise SystemExit(f"Replace the placeholder value for {key} in {path}.")

for key, raw_value in config.items():
    if isinstance(raw_value, str) and raw_value.strip().lower().startswith("replace-with-"):
        raise SystemExit(f"Replace the placeholder value for {key} in {path}.")

project_id = config["FIREBASE_PROJECT_ID"].strip()
if expected_environment == "staging" and project_id != "tenbo-staging":
    raise SystemExit("The staging configuration must target the tenbo-staging Firebase project.")
if expected_environment == "production" and project_id == "tenbo-staging":
    raise SystemExit("Refusing to deploy production using the staging Firebase project.")

print(project_id)
PY
)"

echo "Building $ENVIRONMENT for Firebase project: $CONFIG_VALUES"
flutter build web --release --dart-define-from-file="$CONFIG_FILE"

echo "Deploying Hosting and Firestore Rules to $CONFIG_VALUES"
firebase deploy --only hosting,firestore:rules --project "$CONFIG_VALUES"

echo "Deployment completed: $ENVIRONMENT ($CONFIG_VALUES)"
