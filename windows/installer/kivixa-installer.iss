#define MyAppName "Kivixa"
#define MyAppPublisher "990aa"
#define MyAppURL "https://github.com/990aa/kivixa"
#define MyAppExeName "kivixa.exe"
#define MyAppDesc "A Modern Cross-Platform Notes & Productivity Application"

; ------------------------------------------------------------------------------
; Paths & Versioning
; ------------------------------------------------------------------------------
#define RootDir "..\.."
#define RunnerDir "..\runner"
#define AssetDir RootDir + "\assets"
#define BuildDir RootDir + "\build\windows\x64\runner\Release"
#define VersionInfoFile RootDir + "\VERSION"

; Parse Version
#define FileHandle FileOpen(VersionInfoFile)
#expr FileRead(FileHandle)
#expr FileRead(FileHandle)
#expr FileRead(FileHandle)
#expr FileRead(FileHandle)
#define MajorLine FileRead(FileHandle)
#define MinorLine FileRead(FileHandle)
#define PatchLine FileRead(FileHandle)
#define BuildLine FileRead(FileHandle)
#expr FileClose(FileHandle)
#define Major Copy(MajorLine, Pos("=", MajorLine) + 1)
#define Minor Copy(MinorLine, Pos("=", MinorLine) + 1)
#define Patch Copy(PatchLine, Pos("=", PatchLine) + 1)
#define Build Copy(BuildLine, Pos("=", BuildLine) + 1)
#define AppVersion Major + "." + Minor + "." + Patch

; ------------------------------------------------------------------------------
; Setup Configuration
; ------------------------------------------------------------------------------
[Setup]
AppId={{D37F2C99-F354-4632-A626-68E2F29D6E5A}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
AllowNoIcons=yes
OutputDir={#RootDir}\build_windows_installer
OutputBaseFilename={#MyAppName}-Setup-{#AppVersion}
Compression=lzma2/ultra64
SolidCompression=yes

; Visual Settings
WizardStyle=modern
SetupIconFile={#RunnerDir}\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
; REMOVED: WizardSmallImageFile (This was causing the crash)
DisableWelcomePage=yes

; Architecture
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; WebView2 Runtime bootstrapper for browser functionality
Source: "Evergreen Bootstrapper\\MicrosoftEdgeWebview2Setup.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\{#MyAppExeName}"

[Run]; Install WebView2 Runtime silently (required for browser functionality)
Filename: "{tmp}\\MicrosoftEdgeWebview2Setup.exe"; Parameters: "/silent /install"; StatusMsg: "Installing Microsoft WebView2 Runtime..."; Flags: waituntilterminatedFilename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

; ------------------------------------------------------------------------------
; Code Section: Modern Dark UI
; ------------------------------------------------------------------------------
[Code]

var
  CustomWelcomePage: TWizardPage;
  WelcomeTitle, WelcomeDesc, WelcomeDev: TNewStaticText;
  FooterPanel: TPanel;
  FooterImage: TBitmapImage;
  FooterBitmap: TBitmap;

// ---------------------------------------------------------
// Helper: Gradient Drawing Function
// ---------------------------------------------------------
procedure DrawGradient(Canvas: TCanvas; Rect: TRect; StartColor, EndColor: TColor);
var
  X, Width: Integer;
  R0, G0, B0, R1, G1, B1: Integer;
  R, G, B: Integer;
begin
  R0 := (StartColor) and $FF; G0 := (StartColor shr 8) and $FF; B0 := (StartColor shr 16) and $FF;
  R1 := (EndColor) and $FF;   G1 := (EndColor shr 8) and $FF;   B1 := (EndColor shr 16) and $FF;
  Width := Rect.Right - Rect.Left;
  if Width = 0 then Exit;

  for X := Rect.Left to Rect.Right do
  begin
    R := R0 + ((X - Rect.Left) * (R1 - R0)) div Width;
    G := G0 + ((X - Rect.Left) * (G1 - G0)) div Width;
    B := B0 + ((X - Rect.Left) * (B1 - B0)) div Width;
    Canvas.Pen.Color := (R or (G shl 8) or (B shl 16));
    Canvas.MoveTo(X, Rect.Top);
    Canvas.LineTo(X, Rect.Bottom);
  end;
end;

// ---------------------------------------------------------
// Helper: Create Rect
// ---------------------------------------------------------
function Rect(ALeft, ATop, ARight, ABottom: Integer): TRect;
begin
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Right := ARight;
  Result.Bottom := ABottom;
end;

// ---------------------------------------------------------
// UI Initialization
// ---------------------------------------------------------
procedure InitializeWizard;
var
  FooterHeight: Integer;
begin
  // 1. Set Global Dark Theme Colors
  WizardForm.Color := $282828; 
  WizardForm.InnerPage.Color := $282828;
  WizardForm.MainPanel.Color := $282828;

  // 2. Create the Footer Panel Gradient Accent
  FooterHeight := 45; 
  
  FooterPanel := TPanel.Create(WizardForm);
  with FooterPanel do
  begin
    Parent := WizardForm;
    SetBounds(0, WizardForm.ClientHeight - FooterHeight, WizardForm.ClientWidth, FooterHeight);
    Anchors := [akLeft, akRight, akBottom];
    BevelOuter := bvNone;
    SendToBack; 
  end;

  // Draw Gradient on Footer
  FooterBitmap := TBitmap.Create;
  FooterBitmap.Width := WizardForm.ClientWidth;
  FooterBitmap.Height := FooterHeight;
  DrawGradient(FooterBitmap.Canvas, Rect(0, 0, FooterBitmap.Width, FooterBitmap.Height), $301E14, $553B24);

  FooterImage := TBitmapImage.Create(WizardForm);
  with FooterImage do
  begin
    Parent := FooterPanel;
    Align := alClient;
    Bitmap := FooterBitmap;
    Stretch := True;
  end;

  // Hide standard lines
  WizardForm.Bevel.Visible := False;
  WizardForm.BeveledLabel.Visible := False;

  // 3. Create Custom Welcome Page
  CustomWelcomePage := CreateCustomPage(wpWelcome, '', '');

  // Title Label
  WelcomeTitle := TNewStaticText.Create(WizardForm);
  with WelcomeTitle do
  begin
    Parent := CustomWelcomePage.Surface;
    Caption := 'Welcome to {#MyAppName}';
    Font.Name := 'Segoe UI'; 
    Font.Style := [fsBold];
    Font.Size := 22;
    Font.Color := clWhite;
    Top := 40;
    Left := 20;
    Color := WizardForm.Color; 
  end;

  // Description Label
  WelcomeDesc := TNewStaticText.Create(WizardForm);
  with WelcomeDesc do
  begin
    Parent := CustomWelcomePage.Surface;
    Caption := 'A Modern Cross-Platform Notes & Productivity App.' + #13#10 + #13#10 +
               'This wizard will install {#MyAppName} on your computer.' + #13#10 +
               'Click Next to continue.';
    Font.Name := 'Segoe UI';
    Font.Size := 11;
    Font.Color := $E0E0E0; // Light gray
    Top := 100;
    Left := 20;
    Width := CustomWelcomePage.Surface.Width - 40;
    WordWrap := True;
    Color := WizardForm.Color;
  end;

  // Developer Footer
  WelcomeDev := TNewStaticText.Create(WizardForm);
  with WelcomeDev do
  begin
    Parent := CustomWelcomePage.Surface;
    Caption := 'Developed by {#MyAppPublisher}';
    Font.Size := 9;
    Font.Color := clSilver;
    Top := CustomWelcomePage.Surface.Height - 30;
    Left := 20;
    Color := WizardForm.Color;
  end;
end;

// ---------------------------------------------------------
// Page Handling: Apply Dark Mode text colors dynamically
// ---------------------------------------------------------
procedure CurPageChanged(CurPageID: Integer);
begin
  // 1. Handle Custom Welcome Page Visibility
  if CurPageID = CustomWelcomePage.ID then
  begin
    WizardForm.MainPanel.Visible := False; 
  end
  else
  begin
    WizardForm.MainPanel.Visible := True; 
  end;

  // 2. Force Labels to White for Dark Mode
  WizardForm.PageNameLabel.Font.Color := clWhite;
  WizardForm.PageDescriptionLabel.Font.Color := clSilver;
  
  // Input fields
  WizardForm.DirEdit.Color := $383838;
  WizardForm.DirEdit.Font.Color := clWhite;
  
  // Text labels on pages
  WizardForm.SelectDirLabel.Font.Color := clWhite;
  
  // Tasks List (Checkboxes)
  if WizardForm.TasksList <> nil then
  begin
    WizardForm.TasksList.Color := $282828;
    WizardForm.TasksList.Font.Color := clWhite;
  end;

  // Finished Page
  WizardForm.FinishedLabel.Font.Color := clWhite;
  WizardForm.FinishedHeadingLabel.Font.Color := clWhite;
end;

procedure DeinitializeSetup;
begin
  if Assigned(FooterBitmap) then FooterBitmap.Free;
end;