param(
    [string]$SourceFolder,
    [string]$DestinationFolder,
    [switch]$RunOnce
)

if (-not $RunOnce -and [Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Start-Process -FilePath "powershell.exe" -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-STA",
        "-File", "`"$PSCommandPath`""
    )
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$script:Language = "ja"
$script:SaveFolder = ""
$script:BackupFolder = ""
$script:SettingsDirectory = Join-Path -Path $env:APPDATA -ChildPath "ACRSaveBackup"
$script:SettingsPath = Join-Path -Path $script:SettingsDirectory -ChildPath "settings.json"

$script:Text = @{
    ja = @{
        WindowTitle = "Assetto Corsa Rally セーブバックアップ"
        AppTitle = "Assetto Corsa Rally セーブバックアップ"
        LanguageLabel = "言語"
        SaveFolderLabel = "セーブデータ格納フォルダ"
        BackupFolderLabel = "バックアップ先フォルダ"
        Browse = "選択"
        RunBackup = "バックアップ実行"
        Ready = "セーブデータ格納フォルダとバックアップ先フォルダを選択してください。"
        SelectSaveTitle = "セーブデータ格納フォルダを選択してください"
        SelectBackupTitle = "バックアップ先フォルダを選択してください"
        MissingSave = "セーブデータ格納フォルダを選択してください。"
        MissingBackup = "バックアップ先フォルダを選択してください。"
        SameFolder = "バックアップ先フォルダはセーブデータ格納フォルダとは別の場所を選択してください。"
        NoSav = "選択したセーブデータ格納フォルダに .sav ファイルが見つかりませんでした。"
        Success = "バックアップが完了しました: {0} 個の .sav ファイルを複製しました。`n保存先: {1}"
        Error = "バックアップ中にエラーが発生しました。`n{0}"
        EmptyPath = "未選択"
    }
    en = @{
        WindowTitle = "Assetto Corsa Rally Save Backup"
        AppTitle = "Assetto Corsa Rally Save Backup"
        LanguageLabel = "Language"
        SaveFolderLabel = "Save data folder"
        BackupFolderLabel = "Backup destination folder"
        Browse = "Select"
        RunBackup = "Run Backup"
        Ready = "Select the save data folder and the backup destination folder."
        SelectSaveTitle = "Select the save data folder"
        SelectBackupTitle = "Select the backup destination folder"
        MissingSave = "Please select the save data folder."
        MissingBackup = "Please select the backup destination folder."
        SameFolder = "Please choose a backup destination folder that is different from the save data folder."
        NoSav = "No .sav files were found in the selected save data folder."
        Success = "Backup completed: copied {0} .sav file(s).`nDestination: {1}"
        Error = "An error occurred during backup.`n{0}"
        EmptyPath = "Not selected"
    }
}

function Get-UiText {
    param([string]$Key)
    return $script:Text[$script:Language][$Key]
}

function Load-AppSettings {
    if (-not (Test-Path -LiteralPath $script:SettingsPath -PathType Leaf)) {
        return
    }

    try {
        $settings = Get-Content -LiteralPath $script:SettingsPath -Raw | ConvertFrom-Json

        if ($settings.SaveFolder) {
            $script:SaveFolder = [string]$settings.SaveFolder
        }

        if ($settings.BackupFolder) {
            $script:BackupFolder = [string]$settings.BackupFolder
        }
    }
    catch {
        $script:SaveFolder = ""
        $script:BackupFolder = ""
    }
}

function Save-AppSettings {
    if (-not (Test-Path -LiteralPath $script:SettingsDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $script:SettingsDirectory -Force | Out-Null
    }

    $settings = [PSCustomObject]@{
        SaveFolder = $script:SaveFolder
        BackupFolder = $script:BackupFolder
    }

    $json = $settings | ConvertTo-Json
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($script:SettingsPath, $json, $utf8Bom)
}

function Normalize-PathForCompare {
    param([string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}

function Select-Folder {
    param(
        [string]$Description,
        [string]$InitialPath
    )

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true

    if ($InitialPath -and (Test-Path -LiteralPath $InitialPath -PathType Container)) {
        $dialog.SelectedPath = $InitialPath
    }

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }

    return $null
}

function New-SaveBackup {
    param(
        [Parameter(Mandatory = $true)][string]$SourceFolder,
        [Parameter(Mandatory = $true)][string]$DestinationRoot
    )

    if (-not (Test-Path -LiteralPath $SourceFolder -PathType Container)) {
        throw (Get-UiText "MissingSave")
    }

    if (-not (Test-Path -LiteralPath $DestinationRoot -PathType Container)) {
        throw (Get-UiText "MissingBackup")
    }

    $sourceFull = Normalize-PathForCompare $SourceFolder
    $destinationFull = Normalize-PathForCompare $DestinationRoot

    if ([string]::Equals($sourceFull, $destinationFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw (Get-UiText "SameFolder")
    }

    $saveFiles = Get-ChildItem -LiteralPath $SourceFolder -Filter "*.sav" -File

    if ($saveFiles.Count -eq 0) {
        throw (Get-UiText "NoSav")
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFolderName = "ACR_SaveBackup_$timestamp"
    $backupFolderPath = Join-Path -Path $DestinationRoot -ChildPath $backupFolderName
    New-Item -ItemType Directory -Path $backupFolderPath -ErrorAction Stop | Out-Null

    foreach ($file in $saveFiles) {
        $targetPath = Join-Path -Path $backupFolderPath -ChildPath $file.Name
        Copy-Item -LiteralPath $file.FullName -Destination $targetPath -ErrorAction Stop
    }

    return @{
        Count = $saveFiles.Count
        Path = $backupFolderPath
    }
}

if ($RunOnce) {
    $script:SaveFolder = $SourceFolder
    $script:BackupFolder = $DestinationFolder
}
else {
    Load-AppSettings
}

[xml]$xaml = @"
<Window xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
        xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""
        Width=""720""
        Height=""430""
        MinWidth=""620""
        MinHeight=""390""
        WindowStartupLocation=""CenterScreen""
        ResizeMode=""CanResize""
        Background=""#F5F7FA"">
    <Grid Margin=""24"">
        <Grid.RowDefinitions>
            <RowDefinition Height=""Auto""/>
            <RowDefinition Height=""Auto""/>
            <RowDefinition Height=""*""/>
            <RowDefinition Height=""Auto""/>
        </Grid.RowDefinitions>

        <DockPanel Grid.Row=""0"" LastChildFill=""True"">
            <StackPanel DockPanel.Dock=""Right"" Orientation=""Horizontal"" VerticalAlignment=""Top"">
                <TextBlock x:Name=""LanguageLabel"" VerticalAlignment=""Center"" Margin=""0,0,8,0"" Foreground=""#273142""/>
                <ComboBox x:Name=""LanguageBox"" Width=""120"" SelectedIndex=""0"">
                    <ComboBoxItem Tag=""ja"">日本語</ComboBoxItem>
                    <ComboBoxItem Tag=""en"">English</ComboBoxItem>
                </ComboBox>
            </StackPanel>
            <TextBlock x:Name=""AppTitle""
                       FontSize=""24""
                       FontWeight=""SemiBold""
                       Foreground=""#18202F""
                       TextWrapping=""Wrap""/>
        </DockPanel>

        <Border Grid.Row=""1""
                Margin=""0,22,0,0""
                Background=""#FFFFFF""
                BorderBrush=""#D8DEE8""
                BorderThickness=""1""
                CornerRadius=""6""
                Padding=""18"">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height=""Auto""/>
                    <RowDefinition Height=""14""/>
                    <RowDefinition Height=""Auto""/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width=""170""/>
                    <ColumnDefinition Width=""*""/>
                    <ColumnDefinition Width=""96""/>
                </Grid.ColumnDefinitions>

                <TextBlock x:Name=""SaveFolderLabel"" Grid.Row=""0"" Grid.Column=""0"" VerticalAlignment=""Center"" Foreground=""#273142""/>
                <TextBox x:Name=""SaveFolderBox""
                         Grid.Row=""0""
                         Grid.Column=""1""
                         Height=""32""
                         IsReadOnly=""True""
                         VerticalContentAlignment=""Center""
                         Margin=""0,0,10,0""
                         BorderBrush=""#C8D0DD""/>
                <Button x:Name=""SaveFolderButton""
                        Grid.Row=""0""
                        Grid.Column=""2""
                        Height=""32""/>

                <TextBlock x:Name=""BackupFolderLabel"" Grid.Row=""2"" Grid.Column=""0"" VerticalAlignment=""Center"" Foreground=""#273142""/>
                <TextBox x:Name=""BackupFolderBox""
                         Grid.Row=""2""
                         Grid.Column=""1""
                         Height=""32""
                         IsReadOnly=""True""
                         VerticalContentAlignment=""Center""
                         Margin=""0,0,10,0""
                         BorderBrush=""#C8D0DD""/>
                <Button x:Name=""BackupFolderButton""
                        Grid.Row=""2""
                        Grid.Column=""2""
                        Height=""32""/>
            </Grid>
        </Border>

        <Border Grid.Row=""2""
                Margin=""0,18,0,18""
                Background=""#EEF3F8""
                BorderBrush=""#D8DEE8""
                BorderThickness=""1""
                CornerRadius=""6""
                Padding=""18"">
            <TextBlock x:Name=""StatusText""
                       Foreground=""#273142""
                       TextWrapping=""Wrap""
                       VerticalAlignment=""Center""/>
        </Border>

        <Button x:Name=""RunButton""
                Grid.Row=""3""
                Height=""44""
                HorizontalAlignment=""Right""
                MinWidth=""180""
                Padding=""18,0""
                Background=""#1E6F5C""
                Foreground=""#FFFFFF""
                BorderBrush=""#1E6F5C""
                FontWeight=""SemiBold""/>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$controls = @{}
@(
    "LanguageLabel",
    "LanguageBox",
    "AppTitle",
    "SaveFolderLabel",
    "SaveFolderBox",
    "SaveFolderButton",
    "BackupFolderLabel",
    "BackupFolderBox",
    "BackupFolderButton",
    "StatusText",
    "RunButton"
) | ForEach-Object {
    $controls[$_] = $window.FindName($_)
}

function Refresh-UiText {
    $window.Title = Get-UiText "WindowTitle"
    $controls.AppTitle.Text = Get-UiText "AppTitle"
    $controls.LanguageLabel.Text = Get-UiText "LanguageLabel"
    $controls.SaveFolderLabel.Text = Get-UiText "SaveFolderLabel"
    $controls.BackupFolderLabel.Text = Get-UiText "BackupFolderLabel"
    $controls.SaveFolderButton.Content = Get-UiText "Browse"
    $controls.BackupFolderButton.Content = Get-UiText "Browse"
    $controls.RunButton.Content = Get-UiText "RunBackup"

    $controls.SaveFolderBox.Text = if ($script:SaveFolder) { $script:SaveFolder } else { Get-UiText "EmptyPath" }
    $controls.BackupFolderBox.Text = if ($script:BackupFolder) { $script:BackupFolder } else { Get-UiText "EmptyPath" }

    if (-not $controls.StatusText.Text) {
        $controls.StatusText.Text = Get-UiText "Ready"
    }
}

$controls.LanguageBox.Add_SelectionChanged({
    $selected = $controls.LanguageBox.SelectedItem
    if ($selected -and $selected.Tag) {
        $script:Language = [string]$selected.Tag
        $controls.StatusText.Text = Get-UiText "Ready"
        Refresh-UiText
    }
})

$controls.SaveFolderButton.Add_Click({
    $selectedPath = Select-Folder -Description (Get-UiText "SelectSaveTitle") -InitialPath $script:SaveFolder
    if ($selectedPath) {
        $script:SaveFolder = $selectedPath
        Save-AppSettings
        $controls.SaveFolderBox.Text = $selectedPath
        $controls.StatusText.Text = Get-UiText "Ready"
    }
})

$controls.BackupFolderButton.Add_Click({
    $selectedPath = Select-Folder -Description (Get-UiText "SelectBackupTitle") -InitialPath $script:BackupFolder
    if ($selectedPath) {
        $script:BackupFolder = $selectedPath
        Save-AppSettings
        $controls.BackupFolderBox.Text = $selectedPath
        $controls.StatusText.Text = Get-UiText "Ready"
    }
})

$controls.RunButton.Add_Click({
    try {
        if (-not $script:SaveFolder) {
            throw (Get-UiText "MissingSave")
        }

        if (-not $script:BackupFolder) {
            throw (Get-UiText "MissingBackup")
        }

        $result = New-SaveBackup -SourceFolder $script:SaveFolder -DestinationRoot $script:BackupFolder
        $message = [string]::Format((Get-UiText "Success"), $result.Count, $result.Path)
        $controls.StatusText.Text = $message
        [System.Windows.MessageBox]::Show($message, (Get-UiText "WindowTitle"), "OK", "Information") | Out-Null
    }
    catch {
        $message = [string]::Format((Get-UiText "Error"), $_.Exception.Message)
        $controls.StatusText.Text = $message
        [System.Windows.MessageBox]::Show($message, (Get-UiText "WindowTitle"), "OK", "Error") | Out-Null
    }
})

Refresh-UiText

if ($RunOnce) {
    try {
        $result = New-SaveBackup -SourceFolder $script:SaveFolder -DestinationRoot $script:BackupFolder
        [string]::Format((Get-UiText "Success"), $result.Count, $result.Path)
        exit 0
    }
    catch {
        [Console]::Error.WriteLine([string]::Format((Get-UiText "Error"), $_.Exception.Message))
        exit 1
    }
}

$window.ShowDialog() | Out-Null
