# Assetto Corsa Rally Save Backup

Assetto Corsa Rally Save Backup is a small Windows GUI tool for backing up local Assetto Corsa Rally `.sav` files.

Assetto Corsa Rally does not currently provide cloud save backup support, so this app copies local save files into timestamped backup folders without modifying the original files.

## Features

- Select the save data folder.
- Default the save data folder to `%LOCALAPPDATA%\acr\Saved\SaveGames` on first launch.
- Select the backup destination folder.
- Create a new timestamped backup folder on every run.
- Copy `.sav` files only, leaving the original save files untouched.
- Remember the selected folders until the user selects different folders.
- Switch the interface language between Japanese and English.

## Usage

1. Download or clone this repository.
2. Double-click `Run_ACRSaveBackup.bat`.
3. Select the Assetto Corsa Rally save data folder.
4. Select the backup destination folder.
5. Click the backup button.

Example save folder:

```text
%LOCALAPPDATA%\acr\Saved\SaveGames
```

Backup folders are created with names like:

```text
ACR_SaveBackup_20260707_213045
```

## Saved Settings

The selected folders are saved per Windows user in:

```text
%APPDATA%\ACRSaveBackup\settings.json
```

The app reuses those folders on the next launch unless the user selects different folders.
If no saved folder setting exists yet, the save data folder starts as `%LOCALAPPDATA%\acr\Saved\SaveGames`.

## Documentation

- Japanese: [README_ja.txt](README_ja.txt)
- English: [README_en.txt](README_en.txt)

## Requirements

- Windows
- Windows PowerShell 5.1 or later

No external runtime is required.

## License

MIT License
