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
Filename: "{tmp}\MicrosoftEdgeWebview2Setup.exe"; Parameters: "/silent /install"; StatusMsg: "Installing Microsoft WebView2 Runtime..."; Flags: waituntilterminated

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
    'KIVIXA TERMS AND CONDITIONS' + #13#10 +
    #13#10 +
    'Last Updated: December 2025' + #13#10 +
    'Version: 0.1.7' + #13#10 +
    #13#10 +
    'By using Kivixa, you agree to these terms and conditions.' + #13#10 +
    #13#10 +
    '1. ACCEPTANCE OF TERMS' + #13#10 +
    #13#10 +
    'By downloading, installing, or using the Kivixa application ("App"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, do not use the App.' + #13#10 +
    #13#10 +
    '2. LICENSE' + #13#10 +
    #13#10 +
    'Kivixa grants you a limited, non-exclusive, non-transferable, revocable license to use the App for personal or educational purposes, subject to these Terms.' + #13#10 +
    #13#10 +
    '3. USER DATA' + #13#10 +
    #13#10 +
    '3.1 Local Storage: Your notes, projects, and other data are stored locally on your device. Kivixa does not collect or transmit your personal data to external servers unless you explicitly use sync or backup features.' + #13#10 +
    #13#10 +
    '3.2 Data Responsibility: You are responsible for backing up your data. Kivixa is not responsible for any data loss due to device failure, app updates, or user error.' + #13#10 +
    #13#10 +
    '3.3 Data Clearing: The App provides options to clear your data. Once cleared, data cannot be recovered.' + #13#10 +
    #13#10 +
    '4. INTELLECTUAL PROPERTY' + #13#10 +
    #13#10 +
    '4.1 App Content: The App, including its design, code, graphics, and documentation, is the property of the Kivixa development team and is protected by intellectual property laws.' + #13#10 +
    #13#10 +
    '4.2 User Content: You retain ownership of all content you create using the App. By using the App, you grant Kivixa a limited license to process your content solely for the purpose of providing App functionality.' + #13#10 +
    #13#10 +
    '5. PROHIBITED USES' + #13#10 +
    #13#10 +
    'You agree not to:' + #13#10 +
    '- Reverse engineer, decompile, or disassemble the App' + #13#10 +
    '- Use the App for any illegal or unauthorized purpose' + #13#10 +
    '- Distribute, sell, or sublicense the App' + #13#10 +
    '- Remove any proprietary notices from the App' + #13#10 +
    #13#10 +
    '6. DISCLAIMER OF WARRANTIES' + #13#10 +
    #13#10 +
    'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND. KIVIXA DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.' + #13#10 +
    #13#10 +
    '7. LIMITATION OF LIABILITY' + #13#10 +
    #13#10 +
    'IN NO EVENT SHALL KIVIXA BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATED TO YOUR USE OF THE APP.' + #13#10 +
    #13#10 +
    '8. UPDATES AND MODIFICATIONS' + #13#10 +
    #13#10 +
    'Kivixa may update or modify the App at any time. Continued use of the App after updates constitutes acceptance of any modified Terms.' + #13#10 +
    #13#10 +
    '9. TERMINATION' + #13#10 +
    #13#10 +
    'Kivixa may terminate your access to the App at any time for any reason. Upon termination, you must cease all use of the App.' + #13#10 +
    #13#10 +
    '10. GOVERNING LAW' + #13#10 +
    #13#10 +
    'These Terms shall be governed by and construed in accordance with applicable laws, without regard to conflict of law principles.' + #13#10 +
    #13#10 +
    '11. CONTACT' + #13#10 +
    #13#10 +
    'For questions about these Terms, please visit our repository or contact the development team.';
end;

// ---------------------------------------------------------
// Privacy Policy Text
// ---------------------------------------------------------
function GetPrivacyText: String;
begin
  Result := 
    'KIVIXA PRIVACY POLICY' + #13#10 +
    #13#10 +
    'Last Updated: December 2025' + #13#10 +
    #13#10 +
    '1. INFORMATION WE COLLECT' + #13#10 +
    #13#10 +
    'Kivixa is designed with privacy in mind. We do not collect personal information unless explicitly stated.' + #13#10 +
    #13#10 +
    '1.1 Local Data: All notes, projects, and settings are stored locally on your device.' + #13#10 +
    #13#10 +
    '1.2 No Telemetry: Kivixa does not send usage statistics or telemetry data.' + #13#10 +
    #13#10 +
    '2. DATA STORAGE' + #13#10 +
    #13#10 +
    'Your data is stored in the following locations:' + #13#10 +
    '- Notes and documents: Local device storage' + #13#10 +
    '- Settings and preferences: Local app preferences' + #13#10 +
    '- Calendar events: Local device storage' + #13#10 +
    '- AI models (if downloaded): Local device storage' + #13#10 +
    #13#10 +
    '3. LOCAL AI FEATURES' + #13#10 +
    #13#10 +
    '3.1 On-Device Processing: Kivixa includes optional AI features powered by Small Language Models (SLMs) and Large Language Models (LLMs) that run entirely on your device. All AI processing occurs locally without any data being sent to external servers.' + #13#10 +
    #13#10 +
    '3.2 No Cloud AI: Unlike many applications, Kivixa does NOT use cloud-based AI services. Your notes, documents, and any content processed by AI features never leave your device.' + #13#10 +
    #13#10 +
    '3.3 AI Model Storage: Downloaded AI models are stored locally on your device and can be removed at any time through the app settings.' + #13#10 +
    #13#10 +
    '3.4 Privacy by Design: The local AI architecture ensures complete privacy - your conversations with AI, document analysis, and all AI-assisted features remain entirely private on your device.' + #13#10 +
    #13#10 +
    '4. DATA SHARING' + #13#10 +
    #13#10 +
    'We do not share your data with third parties.' + #13#10 +
    #13#10 +
    '5. SECURITY' + #13#10 +
    #13#10 +
    'While we implement reasonable security measures, no system is completely secure. You are responsible for maintaining the security of your device.' + #13#10 +
    #13#10 +
    '6. CHILDREN''S PRIVACY' + #13#10 +
    #13#10 +
    'Kivixa is not intended for children under 13 years of age.' + #13#10 +
    #13#10 +
    '7. CHANGES TO THIS POLICY' + #13#10 +
    #13#10 +
    'We may update this Privacy Policy from time to time. Continued use of the App constitutes acceptance of any changes.' + #13#10 +
    #13#10 +
    '8. CONTACT' + #13#10 +
    #13#10 +
    'For privacy-related questions, please visit our repository or contact the development team.';
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
    Caption := 'A Modern Cross-Platform Notes & Productivity App.' + #13#10 + #13#10 +
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