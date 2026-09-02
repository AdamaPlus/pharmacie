#define AppName "pharmaguinee"
#define AppVersion "1.0.0"
#define AppPublisher "Adama Keita"
#define AppURL "https://github.com/AdamaPlus"
#define AppExeName "pharmaguinee.exe"
#define AppId "D1A2B3C4-E5F6-4A7B-8C9D-0E1F2A3B4C5D"

[Setup]
AppId={{{#AppId}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
AppCopyright=Copyright © 2026 {#AppPublisher}
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription=Logiciel de gestion de pharmacie
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}

DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=output_setup
OutputBaseFilename=Setup-{#AppName}-{#AppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

DisableProgramGroupPage=yes
DisableReadyPage=no
DisableFinishedPage=no
DisableWelcomePage=no
ShowLanguageDialog=no
UsePreviousAppDir=yes
UsePreviousGroup=yes
UpdateUninstallLogAppName=yes
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le bureau"; GroupDescription: "Raccourcis:"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\Windows\System32\vcruntime140.dll"; DestDir: "{app}"; Flags: external skipifsourcedoesntexist
Source: "C:\Windows\System32\msvcp140.dll"; DestDir: "{app}"; Flags: external skipifsourcedoesntexist
Source: "C:\Windows\System32\vcruntime140_1.dll"; DestDir: "{app}"; Flags: external skipifsourcedoesntexist

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
Name: "{group}\Désinstaller {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
; ✅ RÈGLES FIREWALL (autoriser réseau local)
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""{#AppName} - Sortant"" dir=out action=allow program=""{app}\{#AppExeName}"" enable=yes"; Flags: runhidden; StatusMsg: "Configuration du pare-feu..."
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""{#AppName} - Entrant"" dir=in action=allow program=""{app}\{#AppExeName}"" enable=yes"; Flags: runhidden

; ✅ LANCEMENT POST-INSTALLATION
Filename: "{app}\{#AppExeName}"; Description: "Lancer {#AppName}"; Flags: nowait postinstall skipifsilent; WorkingDir: "{app}"

[UninstallRun]
; ✅ NETTOYAGE RÈGLES FIREWALL
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""{#AppName} - Sortant"""; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""{#AppName} - Entrant"""; Flags: runhidden

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\{#AppPublisher}\{#AppName}"
Type: filesandordirs; Name: "{localappdata}\{#AppPublisher}\{#AppName}"
Type: filesandordirs; Name: "{userappdata}\PharmaGuinee"
Type: filesandordirs; Name: "{localappdata}\PharmaGuinee"
Type: filesandordirs; Name: "{userdocs}\PharmaGuinee"
Type: filesandordirs; Name: "{userdocs}\Pharma Guinée"
Type: filesandordirs; Name: "{tmp}\PharmaGuinee"

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
  if GetWindowsVersion < $0A000000 then begin
    MsgBox('Cette application nécessite Windows 10 ou supérieur.', mbError, MB_OK);
    Result := False;
  end;
end;

function DeleteDataDirectory(Path: String): Boolean;
begin
  Result := (not DirExists(Path)) or DelTree(Path, True, True, True);
end;

function ResetUserData: Boolean;
begin
  { Une réinstallation doit toujours démarrer comme une installation neuve. }
  Result := DeleteDataDirectory(ExpandConstant('{userappdata}\{#AppPublisher}\{#AppName}'));
  Result := DeleteDataDirectory(ExpandConstant('{localappdata}\{#AppPublisher}\{#AppName}')) and Result;
  Result := DeleteDataDirectory(ExpandConstant('{userappdata}\PharmaGuinee')) and Result;
  Result := DeleteDataDirectory(ExpandConstant('{localappdata}\PharmaGuinee')) and Result;
  Result := DeleteDataDirectory(ExpandConstant('{userdocs}\PharmaGuinee')) and Result;
  Result := DeleteDataDirectory(ExpandConstant('{userdocs}\Pharma Guinée')) and Result;
  Result := DeleteDataDirectory(ExpandConstant('{tmp}\PharmaGuinee')) and Result;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  if not ResetUserData then
    Result := 'Impossible de supprimer les anciennes données. Fermez pharmaguinee puis relancez l''installation.'
  else if not ForceDirectories(ExpandConstant('{userappdata}\PharmaGuinee')) then
    Result := 'Impossible de créer le dossier de données dans le profil utilisateur.'
  else
    Result := '';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then begin
    ForceDirectories(ExpandConstant('{userappdata}\PharmaGuinee'));
  end;
end;
