; =====================================================
; Inno Setup Script - PharmaGuinée Installer
; =====================================================

#define AppName "PharmaGuinee"
#define AppVersion "1.0.1"
#define AppPublisher "Adama Keita"
#define AppURL "https://pharmaguinee.com"
#define AppExeName "pharmaguinee.exe"

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
SourceDir=..
OutputDir=output_setup
OutputBaseFilename=PharmaGuinee_Setup_v{#AppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
UsePreviousAppDir=yes
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Desinstaller {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[Dirs]
Name: "{userappdata}\PharmaGuinee"; Flags: uninsalwaysuninstall

[UninstallDelete]
; Supprime toutes les données créées par les versions actuelles et anciennes.
Type: filesandordirs; Name: "{userappdata}\PharmaGuinee"
Type: filesandordirs; Name: "{localappdata}\PharmaGuinee"
Type: filesandordirs; Name: "{userdocs}\PharmaGuinee"
Type: filesandordirs; Name: "{userdocs}\Pharma Guinée"
Type: filesandordirs; Name: "{tmp}\PharmaGuinee"

[Code]
function DeleteDataDirectory(Path: String): Boolean;
begin
  Result := (not DirExists(Path)) or DelTree(Path, True, True, True);
end;

function ResetUserData: Boolean;
begin
  { Une réinstallation doit toujours démarrer comme une installation neuve. }
  Result := DeleteDataDirectory(ExpandConstant('{userappdata}\PharmaGuinee'));
  Result := DeleteDataDirectory(ExpandConstant('{localappdata}\PharmaGuinee')) and Result;
  Result := DeleteDataDirectory(ExpandConstant('{userdocs}\PharmaGuinee')) and Result;
  Result := DeleteDataDirectory(ExpandConstant('{userdocs}\Pharma Guinée')) and Result;
  Result := DeleteDataDirectory(ExpandConstant('{tmp}\PharmaGuinee')) and Result;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  if not ResetUserData then
    Result := 'Impossible de supprimer les anciennes données. Fermez PharmaGuinee puis relancez l''installation.'
  else if not ForceDirectories(ExpandConstant('{userappdata}\PharmaGuinee')) then
    Result := 'Impossible de créer le dossier de données dans le profil utilisateur.'
  else
    Result := '';
end;
