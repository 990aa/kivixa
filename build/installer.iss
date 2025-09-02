; Kivixa Installer Script
#define MyAppName "Kivixa"
#define MyAppVersion "2.0.0"
#define MyAppPublisher "YourCompany"
#define MyAppExeName "kivixa.exe"

[Setup]
AppId={A1B2C3D4-E5F6-47A8-9B0C-1234567890AB}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=build\dist
OutputBaseFilename=KivixaSetup_{#MyAppVersion}
SetupIconFile=build\icon.ico
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
LicenseFile=docs\LICENSE.md

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "dist\kivixa.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Kivixa"; Filename: "{app}\kivixa.exe"; WorkingDir: "{app}"
Name: "{commondesktop}\Kivixa"; Filename: "{app}\kivixa.exe"; Tasks: desktopicon

[Registry]
Root: HKCR; Subkey: ".kivixa"; ValueType: string; ValueName: ""; ValueData: "KivixaFile"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "KivixaFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: "\"{app}\kivixa.exe\" \"%1\""

[Run]
Filename: "{app}\kivixa.exe"; Description: "Launch Kivixa"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"

[CustomMessages]
WelcomeLabel1=Welcome to the Kivixa Setup Wizard

[Code]
// (Add custom wizard branding here)
