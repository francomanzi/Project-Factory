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
        # The name is available, so we can safely exit the loop and continue
        break
    fi
done

mkdir -p "$PROJECT_DIR/Helpers"
mkdir -p "$PROJECT_DIR/reports"

echo "Directory structure created."


echo ""
echo "Do you want to update the attendance thresholds? (yes/no)"
read UPDATE_CHOICE

if [ "$UPDATE_CHOICE" = "yes" ]; then

    while true; do
        echo "Enter new warning threshold (default 75, must be 0-100):"
        read warn
        warn=${warn:-75}  # Default to 75 if user just presses Enter
        if [[ "$warn" =~ ^[0-9]+$ ]] && [ "$warn" -le 100 ] && [ "$warn" -ge 0 ]; then
            break  # Input is valid, exit the loop
        else
            echo "Invalid. Please enter a whole number between 0 and 100."
        fi
    done

    while true; do
        echo "Enter new failure threshold (default 50, must be 0-100):"
        read fail
        fail=${fail:-50}  # Default to 50 if user just presses Enter
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
    python3 --version  # Print the version visibly for the user
else
    echo "Health Check WARNING: python3 was not found. Please install Python 3 to run the app."
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
