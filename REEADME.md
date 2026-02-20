This is a script that creates a students attendance tracker.
It is called project Factory and if someone needs to run the script should usee ./setup_project.sh command.
You will be asked to enter the oroject name ans then choose if you want to update the attendance thresholds and then enter the percentage.
 
This is how thw directory structure is working 
attendance_tracker_{name}/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
└── reports/
    └── reports.log

In addition you can trigger the archive feature 
like when the script is running press Ctrl+C and then it will be interrupted and the things you were doing will be put into another file nameeed attendance_tracker_{name}_archive.tar.gz and then clean your workspace
