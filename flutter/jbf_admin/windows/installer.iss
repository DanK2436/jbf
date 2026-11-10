; Script Inno Setup 6 pour JBF Service Admin
; Cre un installateur professionnel autonome avec raccourcis Bureau/Menu Dmarrer,
; autorisations Pare-feu et enregistrement pour les notifications Windows Toast (AUMID).

#define MyAppName "JBF Service Admin"
#define MyAppVersion "2.0.0"
#define MyAppPublisher "JBF SERVICES SARL"
#define MyAppURL "https://jbf-service.cd"
#define MyAppExeName "jbf_admin.exe"
#define MyAppUserModelID "JBFServices.JBFAdmin.App"

[Setup]
AppId={{5D9D2A92-4C91-4F2A-A814-F2D74868A901}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\JBF Services\JBF Admin
DefaultGroupName=JBF Services
DisableProgramGroupPage=yes
OutputDir=..\installer_output
OutputBaseFilename=JBF-Admin-Setup-x64
SetupIconFile=runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "runner\resources\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\JBF Services\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; AppUserModelID: "{#MyAppUserModelID}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon; AppUserModelID: "{#MyAppUserModelID}"

[Registry]
; Enregistrement officiel de l'application dans le sous-systme de Notifications Windows (Action Center)
Root: HKLM; Subkey: "SOFTWARE\Classes\AppUserModelId\{#MyAppUserModelID}"; ValueType: string; ValueName: "DisplayName"; ValueData: "{#MyAppName}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "SOFTWARE\Classes\AppUserModelId\{#MyAppUserModelID}"; ValueType: string; ValueName: "IconUri"; ValueData: "{app}\app_icon.ico"; Flags: uninsdeletekey
Root: HKLM; Subkey: "SOFTWARE\Classes\AppUserModelId\{#MyAppUserModelID}"; ValueType: dword; ValueName: "ShowInSettings"; ValueData: 1; Flags: uninsdeletekey

[Run]
; Autorisation Pare-feu Windows pour le bon fonctionnement des flux API / Supabase / Brevo
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""{#MyAppName}"" dir=in action=allow program=""{app}\{#MyAppExeName}"" enable=yes"; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""{#MyAppName} Out"" dir=out action=allow program=""{app}\{#MyAppExeName}"" enable=yes"; Flags: runhidden
; Lancement optionnel aprs installation
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Nettoyage des autorisations pare-feu lors de la dsinstallation
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""{#MyAppName}"""; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""{#MyAppName} Out"""; Flags: runhidden
