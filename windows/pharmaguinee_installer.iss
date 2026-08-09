; =====================================================
; Inno Setup Script - PharmaGuinée Installer
; À compiler avec Inno Setup 6+ sur Windows
; =====================================================

#define AppName "PharmaGuinée"
#define AppVersion "1.0.0"
#define AppPublisher "Adama Keita"
#define AppURL "https://pharmaguinee.com"
#define AppExeName "pharmaguinee.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{8A3F2C1D-4B7E-4F2A-9C3D-1E5F6A7B8C9D}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
LicenseFile=
OutputDir=..\output_setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
WizardSizePercent=120
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Tous les fichiers du build Flutter Windows
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Icône de l'application
Source: "..\assets\images\app_icon.png"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Raccourci dans le menu Démarrer
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\app_icon.png"
Name: "{group}\Désinstaller {#AppName}"; Filename: "{uninstallexe}"

; Raccourci sur le bureau (optionnel)
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\app_icon.png"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
