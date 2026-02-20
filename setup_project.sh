#!/bin/bash

cleanup() {
    echo ""
    echo "Script interrupted. Saving current progress..."
    tar -czf "${PROJECT_DIR}_archive.tar.gz" "$PROJECT_DIR" 2>/dev/null || echo "Nothing to archive yet."
    rm -rf "$PROJECT_DIR" 2>/dev/null
    echo "Archive saved as: ${PROJECT_DIR}_archive.tar.gz"
    echo "Incomplete directory removed. Exiting."
    exit 1
}

trap cleanup SIGINT

while true; do
    echo "Enter a project name suffix (press Enter to use default: v1):"
    read INPUT_NAME
    INPUT_NAME=${INPUT_NAME:-v1}
    PROJECT_DIR="attendance_tracker_${INPUT_NAME}"
    if [ -d "$PROJECT_DIR" ]; then
        echo "A directory named '$PROJECT_DIR' already exists. Please try a different name."
    else
        break
    fi
done

mkdir -p "$PROJECT_DIR/Helpers"
mkdir -p "$PROJECT_DIR/reports"
echo "Directory structure created."

cat > "$PROJECT_DIR/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime
def run_attendance_check():
# 1. Load Config
with open('Helpers/config.json', 'r') as f:
config = json.load(f)
# 2. Archive old reports.log if it exists
if os.path.exists('reports/reports.log'):
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
os.rename('reports/reports.log',
f'reports/reports_{timestamp}.log.archive')
# 3. Process Data
with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log',
'w') as log:
reader = csv.DictReader(f)
total_sessions = config['total_sessions']
log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
for row in reader:
name = row['Names']
email = row['Email']
attended = int(row['Attendance Count'])
# Simple Math: (Attended / Total) * 100
attendance_pct = (attended / total_sessions) * 100
message = ""
if attendance_pct < config['thresholds']['failure']:
message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}
%. You will fail this class."
elif attendance_pct < config['thresholds']['warning']:
message = f"WARNING: {name}, your attendance is
{attendance_pct:.1f}%. Please be careful."
if message:
if config['run_mode'] == "live":
log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}
\n")
print(f"Logged alert for {name}")
else:
print(f"[DRY RUN] Email to {email}: {message}")
if __name__ == "__main__":
run_attendance_check()

EOF

cat > "$PROJECT_DIR/Helpers/assets.csv" << 'EOF'
Email Names Attendance Count Absence Count
alice@example.com Alice Johnson 14 1
bob@example.com Bob Smith 7 8
charlie@example.com Charlie Davis 4 11
diana@example.com Diana Prince 15 0
EOF

cat > "$PROJECT_DIR/Helpers/config.json" << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

echo "
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your
attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie
Davis, your attendance is 26.7%. You will fail this class." > "$PROJECT_DIR/reports/reports.log"
echo "All files created."

echo ""
echo "Do you want to update the attendance thresholds? (yes/no)"
read UPDATE_CHOICE

if [ "$UPDATE_CHOICE" = "yes" ]; then

    while true; do
        echo "Enter new warning threshold (default 75, must be 0-100):"
        read warn
        warn=${warn:-75}
        if [[ "$warn" =~ ^[0-9]+$ ]] && [ "$warn" -le 100 ] && [ "$warn" -ge 0 ]; then
            break
        else
            echo "Invalid. Please enter a whole number between 0 and 100."
        fi
    done

    while true; do
        echo "Enter new failure threshold (default 50, must be 0-100):"
        read fail
        fail=${fail:-50}
        if [[ "$fail" =~ ^[0-9]+$ ]] && [ "$fail" -le 100 ] && [ "$fail" -ge 0 ]; then
            break
        else
            echo "Invalid. Please enter a whole number between 0 and 100."
        fi
    done

    if [ "$fail" -ge "$warn" ]; then
        echo "Error: Failure threshold ($fail) must be less than warning threshold ($warn)."
        exit 1
    fi

    sed -i '' "s/\"warning_threshold\": [0-9]*/\"warning_threshold\": $warn/" "$PROJECT_DIR/Helpers/config.json"
    sed -i '' "s/\"failure_threshold\": [0-9]*/\"failure_threshold\": $fail/" "$PROJECT_DIR/Helpers/config.json"

    echo "Thresholds updated in config.json."
else
    echo "Keeping default thresholds (Warning: 75%, Failure: 50%)."
fi

echo ""
echo "Running health check..."

if python3 --version > /dev/null 2>&1; then
    echo "Health Check PASSED: python3 is installed."
    python3 --version
else
    echo "Health Check WARNING: python3 was not found. Please install Python 3."
fi

echo ""
echo "Verifying directory structure..."

STRUCTURE_OK=true

for EXPECTED_PATH in \
    "$PROJECT_DIR/attendance_checker.py" \
    "$PROJECT_DIR/Helpers/assets.csv" \
    "$PROJECT_DIR/Helpers/config.json" \
    "$PROJECT_DIR/reports/reports.log"
do
    if [ -e "$EXPECTED_PATH" ]; then
        echo "  FOUND: $EXPECTED_PATH"
    else
        echo "  MISSING: $EXPECTED_PATH"
        STRUCTURE_OK=false
    fi
done

if [ "$STRUCTURE_OK" = true ]; then
    echo "Structure verification: PASSED"
else
    echo "Structure verification: FAILED - some files are missing."
fi

echo ""
echo "Setup complete. Your project is ready at: $PROJECT_DIR"
echo "To run the app: cd $PROJECT_DIR && python3 attendance_checker.py"
