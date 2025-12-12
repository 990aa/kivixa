#define MyAppName "Kivixa"
#define MyAppPublisher "990aa"
#define MyAppURL "https://github.com/990aa/kivixa"
#define MyAppExeName "Kivixa.exe"
#define MyAppDesc "A Modern Cross-Platform Notes & Productivity Application"

; ------------------------------------------------------------------------------
; Version Parser
; ------------------------------------------------------------------------------
#define VersionInfoFile "..\..\VERSION"
#define FileHandle FileOpen(VersionInfoFile)

; Skip header comments (4 lines)
#expr FileRead(FileHandle)
#expr FileRead(FileHandle)
#expr FileRead(FileHandle)
#expr FileRead(FileHandle)

; Read Version Definitions
#define MajorLine FileRead(FileHandle)
#define MinorLine FileRead(FileHandle)
#define PatchLine FileRead(FileHandle)
#define BuildLine FileRead(FileHandle)
#expr FileClose(FileHandle)

; Parse Values
#define Major Copy(MajorLine, Pos("=", MajorLine) + 1)
#define Minor Copy(MinorLine, Pos("=", MinorLine) + 1)
#define Patch Copy(PatchLine, Pos("=", PatchLine) + 1)
#define Build Copy(BuildLine, Pos("=", BuildLine) + 1)

#define AppVersion Major + "." + Minor + "." + Patch
#define VersionInfoVersion Major + "." + Minor + "." + Patch + "." + Build

; ------------------------------------------------------------------------------
; Main Setup Configuration
; ------------------------------------------------------------------------------
[Setup]
AppId={{D37F2C99-F354-4632-A626-68E2F29D6E5A}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppVerName={#MyAppName} {#AppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}
AppComments={#MyAppDesc}
VersionInfoVersion={#VersionInfoVersion}

; Directory Settings
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
AllowNoIcons=yes

; Output Settings
OutputDir=..\..\build\windows\installer
OutputBaseFilename={#MyAppName}-Setup-{#AppVersion}
Compression=lzma2/ultra64
SolidCompression=yes

; Visual & Style Settings
WizardStyle=modern
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
WindowVisible=yes

; Architecture
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main Application Files
Source: "..\..\build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"; IconFilename: "{app}\\{#MyAppExeName}"
Name: "{autodesktop}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\\{#MyAppExeName}"

[Run]
Filename: "{app}\\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

; ------------------------------------------------------------------------------
; Code Section
; ------------------------------------------------------------------------------
[Code]
// -----------------------------------------------------------------------------
// Visual Styling: Gradient Background
// -----------------------------------------------------------------------------
procedure DrawGradient(Canvas: TCanvas; Rect: TRect; StartColor, EndColor: TColor);
var
  Y: Integer;
  R0, G0, B0, R1, G1, B1: Integer;
  R, G, B: Integer;
  LineColor: TColor;
begin
  R0 := (StartColor) and $FF;
  G0 := (StartColor shr 8) and $FF;
  B0 := (StartColor shr 16) and $FF;
  
  R1 := (EndColor) and $FF;
  G1 := (EndColor shr 8) and $FF;
  B1 := (EndColor shr 16) and $FF;

  for Y := Rect.Top to Rect.Bottom do
  begin
    R := R0 + MulDiv(Y - Rect.Top, R1 - R0, Rect.Bottom - Rect.Top);
    G := G0 + MulDiv(Y - Rect.Top, G1 - G0, Rect.Bottom - Rect.Top);
    B := B0 + MulDiv(Y - Rect.Top, B1 - B0, Rect.Bottom - Rect.Top);
    
    LineColor := RGB(R, G, B);
    Canvas.Pen.Color := LineColor;
    Canvas.MoveTo(Rect.Left, Y);
    Canvas.LineTo(Rect.Right, Y);
  end;
end;

var
  BackgroundBitmap: TBitmap;
  BackgroundPanel: TPanel;

procedure InitializeWizard;
var
  WWidth, WHeight: Integer;
begin
  ; Create a subtle gradient panel behind the wizard content
  ; Note: VCL styling in Inno is limited. We'll apply this to the main form background.
  
  WWidth := WizardForm.ClientWidth;
  WHeight := WizardForm.ClientHeight;
  
  BackgroundPanel := TPanel.Create(WizardForm);
  BackgroundPanel.Parent := WizardForm;
  BackgroundPanel.SetBounds(0, 0, WWidth, WHeight);
  BackgroundPanel.SendToBack; 
  ; Anchor to ensure it resizes (though Wizard is usually fixed size)
  BackgroundPanel.Anchors := [akLeft, akTop, akRight, akBottom];
  
  ; Prepare the bitmap
  BackgroundBitmap := TBitmap.Create;
  BackgroundBitmap.Width := WWidth;
  BackgroundBitmap.Height := WHeight;
  
  ; Draw Gradient: Deep Purple/Blue to Lighter Blue (Modern Tech Feel)
  ; Start: #2c3e50 (Dark Blue/Grey) -> End: #4ca1af (Teal/Blue)
  ; Converting Hex to RGB Int: $00503E2C (BGR) -> $00AF014C
  ; Let's use standard Windows colors or RGB helper
  ; Start: RGB(30, 30, 50) -> End: RGB(60, 60, 100)
  
  DrawGradient(BackgroundBitmap.Canvas, Rect(0, 0, WWidth, WHeight), $503030, $905050); ; BGR format in Pascal? No, TColor is RGB usually, let's verify.
  ; Actually Inno TColor is usually $00BBGGRR.
  ; Let's try a safe "Kivixa Blue" gradient.
  ; Start: Dark Blue ($330000 -> B=33)
  ; End: Lighter Blue ($662200 -> B=66, G=22)
  
  DrawGradient(BackgroundBitmap.Canvas, Rect(0, 0, WWidth, WHeight), $6A2B35, $C26B22); ; Just some pleasant values
  
  ; Assign to panel? TPanel doesn't have a Bitmap property directly exposed easily for background.
  ; Easier: Image object.
  with TBitmapImage.Create(WizardForm) do
  begin
    Parent := BackgroundPanel;
    Align := alClient;
    Bitmap := BackgroundBitmap;
    Stretch := True;
  end;
  
  ; Make labels transparent so they look good on gradient
  WizardForm.WelcomeLabel1.Color := clNone;
  WizardForm.WelcomeLabel2.Color := clNone;
  WizardForm.FinishedLabel.Color := clNone;
  WizardForm.FinishedHeadingLabel.Color := clNone;
end;

procedure DeinitializeSetup;
begin
  if Assigned(BackgroundBitmap) then BackgroundBitmap.Free;
end;

; -----------------------------------------------------------------------------
; Uninstall Logic: Cleanup User Data
; -----------------------------------------------------------------------------
procedure CleanupUserData;
var
  AppDataPath: String;
begin
  ; Kivixa stores data in Documents\Kivixa
  AppDataPath := ExpandConstant('{userdocs}\{#MyAppName}');
  
  if DirExists(AppDataPath) then
  begin
    ; Recursively delete the directory
    DelTree(AppDataPath, True, True, True);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    ; Prompt the user
    if MsgBox('Do you also want to delete all user data (notes, sketches) stored in Documents\Kivixa?' + #13#10 +
              'This action cannot be undone.', mbConfirmation, MB_YESNO) = IDYES then
    begin
      CleanupUserData();
    end;
  end;
end;