#define MyAppName "Kivixa"
#define MyAppPublisher "990aa"
#define MyAppURL "https://github.com/990aa/kivixa"
#define MyAppExeName "kivixa.exe"
#define MyAppDesc "A privacy-first cross-platform productivity workspace for notes, sketching, planning, and local AI assistance."

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
DisableWelcomePage=yes

; Architecture
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Core Application Files
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; WebView2 Runtime bootstrapper
Source: "Evergreen Bootstrapper\MicrosoftEdgeWebview2Setup.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\{#MyAppExeName}"

[Run]
; Install WebView2 Runtime silently (required for browser functionality)
Filename: "{tmp}\MicrosoftEdgeWebview2Setup.exe"; Parameters: "/silent /install"; StatusMsg: "Installing Microsoft WebView2 Runtime..."; Flags: waituntilterminated skipifsilent

; Launch Application
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

; ------------------------------------------------------------------------------
; Code Section: Modern Light UI with Purple/Blue Theme
; ------------------------------------------------------------------------------
[Code]

var
  CustomWelcomePage: TWizardPage;
  TermsPage: TWizardPage;
  PrivacyPage: TWizardPage;
  WelcomeTitle, WelcomeDesc, WelcomeDev: TNewStaticText;
  TermsMemo, PrivacyMemo: TNewMemo;
  TermsCheckBox, PrivacyCheckBox: TNewCheckBox;
  FooterPanel: TPanel;
  FooterImage: TBitmapImage;
  FooterBitmap: TBitmap;

// ---------------------------------------------------------
// Color Constants - Light Theme with Purple/Blue accents
// ---------------------------------------------------------
const
  // Background colors (light greys)
  BgLight = $F5F5F5;        // Very light grey background
  BgMedium = $EBEBEB;       // Medium light grey
  BgDark = $E0E0E0;         // Slightly darker grey for contrast
  
  // Accent colors (purple/blue)
  AccentPurple = $A06040;   // Purple accent (BGR: light purple)
  AccentBlue = $C08050;     // Blue accent (BGR: soft blue)
  AccentGradientStart = $C08060; // Light blue-purple
  AccentGradientEnd = $905040;   // Deeper purple
  
  // Text colors
  TextPrimary = $202020;    // Dark text on light background
  TextSecondary = $606060;  // Secondary text
  TextMuted = $909090;      // Muted text

// ---------------------------------------------------------
// Helper: Gradient Drawing Function
// ---------------------------------------------------------
procedure DrawGradient(Canvas: TCanvas; R: TRect; StartColor, EndColor: TColor);
var
  X, W: Integer;
  R0, G0, B0, R1, G1, B1: Integer;
  RC, GC, BC: Integer;
begin
  R0 := (StartColor) and $FF; G0 := (StartColor shr 8) and $FF; B0 := (StartColor shr 16) and $FF;
  R1 := (EndColor) and $FF;   G1 := (EndColor shr 8) and $FF;   B1 := (EndColor shr 16) and $FF;
  W := R.Right - R.Left;
  if W = 0 then Exit;

  for X := R.Left to R.Right do
  begin
    RC := R0 + ((X - R.Left) * (R1 - R0)) div W;
    GC := G0 + ((X - R.Left) * (G1 - G0)) div W;
    BC := B0 + ((X - R.Left) * (B1 - B0)) div W;
    Canvas.Pen.Color := (RC or (GC shl 8) or (BC shl 16));
    Canvas.MoveTo(X, R.Top);
    Canvas.LineTo(X, R.Bottom);
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
// Terms and Conditions Text
// ---------------------------------------------------------
function GetTermsText: String;
begin
  Result :=
    'KIVIXA TERMS AND CONDITIONS' + #13#10 + #13#10 +
    'Last Updated: May 2026' + #13#10 + #13#10 +
    '1. AGREEMENT TO TERMS' + #13#10 +
    'These Terms of Service constitute a legally binding agreement made between you and the Kivixa Project (''we,'', ''us,'' or ''our''), concerning your access to and use of the Kivixa application and any related services. By accessing the App, you acknowledge that you have read, understood, and agreed to be bound by all of these Terms.' + #13#10 + #13#10 +
    '2. INTELLECTUAL PROPERTY RIGHTS' + #13#10 +
    'Our Content: Unless otherwise indicated, the App, including source code, databases, functionality, software, and graphic designs, are owned or controlled by us and are protected by copyright and trademark laws. Access is provided under applicable open-source licenses.' + #13#10 + #13#10 +
    'User Content: You retain full ownership of any data you create (''User Content''). Because Kivixa is local-first, we have no access to, nor control over, your User Content.' + #13#10 + #13#10 +
    '3. LOCAL-FIRST ARCHITECTURE & DATA RESPONSIBILITY' + #13#10 +
    'Zero-Knowledge: You acknowledge that Kivixa operates on a ''Zero-Knowledge'' model. All data is stored locally on your device.' + #13#10 + #13#10 +
    'Backup Responsibility: We do not provide cloud backup services. You are solely responsible for maintaining backups of your data. We are not liable for any data loss resulting from hardware failure, software bugs, app uninstallation, or device loss.' + #13#10 + #13#10 +
    '4. LOCAL AI & CONTENT DISCLAIMER' + #13#10 +
    'Kivixa provides tools for local AI processing.' + #13#10 + #13#10 +
    'Accuracy: AI-generated content may be inaccurate, biased, or ''hallucinated.'' You should not rely on AI-generated output for medical, legal, financial, or high-stakes decision-making.' + #13#10 + #13#10 +
    'Liability: The Kivixa Project is not responsible for any content generated by local models or any actions you take based on such content.' + #13#10 + #13#10 +
    '5. PROHIBITED ACTIVITIES' + #13#10 +
    'You may not use the App to:' + #13#10 +
    'Circulate malicious software or scripts.' + #13#10 +
    'Engage in any activity that violates local or international laws.' + #13#10 +
    'Attempt to bypass or modify the App’s security features.' + #13#10 + #13#10 +
    '6. LIMITATION OF LIABILITY & DISCLAIMER' + #13#10 +
    'KIVIXA IS PROVIDED ON AN ''AS-IS'' AND ''AS-AVAILABLE'' BASIS. TO THE FULLEST EXTENT PERMITTED BY LAW, WE DISCLAIM ALL WARRANTIES. WE WILL NOT BE LIABLE FOR ANY DAMAGES OF ANY KIND ARISING FROM THE USE OF THE APP, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT, INCIDENTAL, PUNITIVE, AND CONSEQUENTIAL DAMAGES.';
end;

// ---------------------------------------------------------
// Privacy Policy Text
// ---------------------------------------------------------
function GetPrivacyText: String;
begin
  Result :=
    'KIVIXA PRIVACY POLICY' + #13#10 + #13#10 +
    'Last Updated: May 2026' + #13#10 + #13#10 +
    '1. OUR PRIVACY PHILOSOPHY' + #13#10 +
    'Privacy is not a "feature" of Kivixa; it is the foundation. Our architecture is designed so that your data is never collected, stored on our servers, or sold to third parties.' + #13#10 + #13#10 +
    '2. DATA COLLECTION & PROCESSING' + #13#10 +
    'Personal Information: We do not require an account to use Kivixa. We do not collect your name, email address, or phone number.' + #13#10 + #13#10 +
    'Usage Data (Telemetry): Kivixa does not include telemetry or "phone home" tracking. We do not know how often you use the app or which features you prefer.' + #13#10 + #13#10 +
    'Crash Reporting: Optional crash reports may be generated by your operating system (Android/Windows). These are governed by your OS privacy settings and are not directly collected by Kivixa.' + #13#10 + #13#10 +
    '3. LOCAL PROCESSING' + #13#10 +
    'On-Device AI: All AI analysis, document summarization, and chat interactions occur strictly on your device''s CPU/GPU. No text or data is transmitted to the cloud for processing.' + #13#10 + #13#10 +
    'Native Engines: The Rust-based engines process data locally in your device''s memory. No data is cached or sent externally.' + #13#10 + #13#10 +
    '4. THIRD-PARTY SERVICES' + #13#10 +
    'While Kivixa is local-first, you may interact with third-party services through:' + #13#10 +
    'GitHub/F-Droid/Winget: If you download updates, these platforms may collect standard technical metadata (IP address, device type) required for file delivery.' + #13#10 + #13#10 +
    'External Links: If you click a link within the app, you will be directed to an external site governed by its own privacy policy.' + #13#10 + #13#10 +
    '5. DATA SECURITY' + #13#10 +
    'Because your data is stored locally, its security depends on the security of your device. We recommend using encrypted storage, biometrics, or strong passwords to protect your device from unauthorized access.' + #13#10 + #13#10 +
    '6. CHILDREN''S PRIVACY' + #13#10 +
    'Kivixa does not knowingly collect data from anyone. Because all data stays on your device, we have no way to identify the age of our users. We encourage parents to monitor their children''s device usage.' + #13#10 + #13#10 +
    '7. CONTACT INFORMATION' + #13#10 +
    'For any questions regarding these policies, please open an issue on our official GitHub repository.';
end;

// ---------------------------------------------------------
// Checkbox Click Handler
// ---------------------------------------------------------
procedure CheckBoxClick(Sender: TObject);
begin
  // Enable/disable next button based on checkbox state
  WizardForm.NextButton.Enabled := 
    (WizardForm.CurPageID <> TermsPage.ID) or TermsCheckBox.Checked;
  WizardForm.NextButton.Enabled := 
    (WizardForm.CurPageID <> PrivacyPage.ID) or PrivacyCheckBox.Checked;
end;

// ---------------------------------------------------------
// UI Initialization
// ---------------------------------------------------------
procedure InitializeWizard;
var
  FooterHeight: Integer;
begin
  // 1. Set Global Light Theme Colors
  WizardForm.Color := BgLight; 
  WizardForm.InnerPage.Color := BgLight;
  WizardForm.MainPanel.Color := BgMedium;

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

  // Draw Gradient on Footer with purple/blue colors
  FooterBitmap := TBitmap.Create;
  FooterBitmap.Width := WizardForm.ClientWidth;
  FooterBitmap.Height := FooterHeight;
  DrawGradient(FooterBitmap.Canvas, Rect(0, 0, FooterBitmap.Width, FooterBitmap.Height), AccentGradientStart, AccentGradientEnd);

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
    Font.Color := TextPrimary;
    Top := 40;
    Left := 20;
    Color := WizardForm.Color; 
  end;

  // Description Label
  WelcomeDesc := TNewStaticText.Create(WizardForm);
  with WelcomeDesc do
  begin
    Parent := CustomWelcomePage.Surface;
    Caption := 'A privacy-first cross-platform productivity workspace for notes, sketching, planning, and local AI assistance.' + #13#10 + #13#10 +
                'This wizard will install {#MyAppName} on your computer.' + #13#10 +
                'Click Next to review the Terms and Conditions.';
    Font.Name := 'Segoe UI';
    Font.Size := 11;
    Font.Color := TextSecondary;
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
    Font.Color := TextMuted;
    Top := CustomWelcomePage.Surface.Height - 30;
    Left := 20;
    Color := WizardForm.Color;
  end;

  // 4. Create Terms and Conditions Page
  TermsPage := CreateCustomPage(CustomWelcomePage.ID, 'Terms and Conditions', 'Please read and accept the terms and conditions');
  
  TermsMemo := TNewMemo.Create(WizardForm);
  with TermsMemo do
  begin
    Parent := TermsPage.Surface;
    Left := 0;
    Top := 0;
    Width := TermsPage.Surface.Width;
    Height := TermsPage.Surface.Height - 40;
    ScrollBars := ssVertical;
    ReadOnly := True;
    Text := GetTermsText;
    Color := $FFFFFF;
    Font.Name := 'Segoe UI';
    Font.Size := 9;
    Font.Color := TextPrimary;
  end;
  
  TermsCheckBox := TNewCheckBox.Create(WizardForm);
  with TermsCheckBox do
  begin
    Parent := TermsPage.Surface;
    Left := 0;
    Top := TermsPage.Surface.Height - 30;
    Width := TermsPage.Surface.Width;
    Caption := 'I have read and accept the Terms and Conditions';
    Font.Name := 'Segoe UI';
    Font.Color := TextPrimary;
    OnClick := @CheckBoxClick;
  end;

  // 5. Create Privacy Policy Page
  PrivacyPage := CreateCustomPage(TermsPage.ID, 'Privacy Policy', 'Please read and accept the privacy policy');
  
  PrivacyMemo := TNewMemo.Create(WizardForm);
  with PrivacyMemo do
  begin
    Parent := PrivacyPage.Surface;
    Left := 0;
    Top := 0;
    Width := PrivacyPage.Surface.Width;
    Height := PrivacyPage.Surface.Height - 40;
    ScrollBars := ssVertical;
    ReadOnly := True;
    Text := GetPrivacyText;
    Color := $FFFFFF;
    Font.Name := 'Segoe UI';
    Font.Size := 9;
    Font.Color := TextPrimary;
  end;
  
  PrivacyCheckBox := TNewCheckBox.Create(WizardForm);
  with PrivacyCheckBox do
  begin
    Parent := PrivacyPage.Surface;
    Left := 0;
    Top := PrivacyPage.Surface.Height - 30;
    Width := PrivacyPage.Surface.Width;
    Caption := 'I have read and accept the Privacy Policy';
    Font.Name := 'Segoe UI';
    Font.Color := TextPrimary;
    OnClick := @CheckBoxClick;
  end;
end;

// ---------------------------------------------------------
// Skip Custom Pages During Silent Install
// ---------------------------------------------------------
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  // If the installer is running via command line with /SILENT or /VERYSILENT
  if WizardSilent then
  begin
    // Skip all our custom pages that require manual clicks
    if (PageID = CustomWelcomePage.ID) or 
       (PageID = TermsPage.ID) or 
       (PageID = PrivacyPage.ID) then
    begin
      Result := True;
    end;
  end;
end;

// ---------------------------------------------------------
// Page Handling: Apply Light Mode text colors dynamically
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

  // 2. Handle Terms Page - Disable Next until accepted
  if CurPageID = TermsPage.ID then
  begin
    WizardForm.NextButton.Enabled := TermsCheckBox.Checked;
  end;
  
  // 3. Handle Privacy Page - Disable Next until accepted
  if CurPageID = PrivacyPage.ID then
  begin
    WizardForm.NextButton.Enabled := PrivacyCheckBox.Checked;
  end;

  // 4. Force Labels to dark text for Light Mode
  WizardForm.PageNameLabel.Font.Color := TextPrimary;
  WizardForm.PageDescriptionLabel.Font.Color := TextSecondary;
  
  // Input fields
  WizardForm.DirEdit.Color := $FFFFFF;
  WizardForm.DirEdit.Font.Color := TextPrimary;
  
  // Text labels on pages
  WizardForm.SelectDirLabel.Font.Color := TextPrimary;
  
  // Tasks List (Checkboxes)
  if WizardForm.TasksList <> nil then
  begin
    WizardForm.TasksList.Color := BgLight;
    WizardForm.TasksList.Font.Color := TextPrimary;
  end;

  // Finished Page
  WizardForm.FinishedLabel.Font.Color := TextPrimary;
  WizardForm.FinishedHeadingLabel.Font.Color := TextPrimary;
end;

procedure DeinitializeSetup;
begin
  if Assigned(FooterBitmap) then FooterBitmap.Free;
end;