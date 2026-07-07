Assetto Corsa Rally Save Backup
===============================

Overview
--------
This is a small Windows GUI app for copying local Assetto Corsa Rally save data (.sav files) to a selected backup destination.
The original save files are not modified.

Features
--------
- Select the save data folder.
  Example: C:\Users\User\App Data\Local\acr\Saved\SaveGames
- Select the backup destination folder.
- Create a new timestamped folder each time a backup is run.
  Example: ACR_SaveBackup_20260707_213045
- Copy .sav files from the selected save data folder into the new backup folder.
- The interface supports Japanese and English.
- The selected folders are saved per Windows user and restored on the next launch until you choose different folders.

How to Use
----------
1. Double-click Run_ACRSaveBackup.bat.
2. Select the save data folder.
3. Select the backup destination folder.
4. Click Run Backup.

Folder Settings
---------------
The selected save data folder and backup destination folder are saved to:

%APPDATA%\ACRSaveBackup\settings.json

The app reuses these folders on the next launch unless you select different folders.

Execution Policy
----------------
Run_ACRSaveBackup.bat starts the included PowerShell script with ExecutionPolicy Bypass.
This applies only to launching this app and does not change the system-wide Windows setting.

Notes
-----
- The app copies .sav files directly inside the selected save data folder.
- Choose a backup destination folder that is different from the save data folder.
- It is recommended to close the game before running a backup.

Publishing to GitHub
--------------------
1. Create a new repository on GitHub.
2. Add the contents of this folder to the repository.
3. In an environment where Git is available, run:

   git init
   git add .
   git commit -m "Initial release"
   git branch -M main
   git remote add origin https://github.com/YOUR_NAME/YOUR_REPOSITORY.git
   git push -u origin main

License
-------
Add a LICENSE file before publishing if you need a specific license.
