#define MyAppName "Key Atlas"
#ifndef MyAppVersion
  #define MyAppVersion "dev"
#endif
#define MyAppPublisher "Luis Fer"
#define MyAppExeName "KeyAtlas.exe"

[Setup]
AppId={{D6B5B7E5-7C53-4CB9-8B27-6C08E917BB9D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\KeyAtlas
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=KeyAtlas-Setup-{#MyAppVersion}-windows-x64
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "startup"; Description: "Iniciar Key Atlas al iniciar Windows"; GroupDescription: "Opciones adicionales:"; Flags: checkedonce

[Files]
Source: "..\dist\KeyAtlas\KeyAtlas.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\dist\KeyAtlas\README-Windows.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\dist\KeyAtlas\config\*"; DestDir: "{app}\config"; Flags: ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist
Source: "..\dist\KeyAtlas\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist

[Icons]
Name: "{group}\Key Atlas"; Filename: "{app}\{#MyAppExeName}"
Name: "{userstartup}\Key Atlas"; Filename: "{app}\{#MyAppExeName}"; Tasks: startup

[Run]
Filename: "{app}\{#MyAppExeName}"; Parameters: "--open-config"; Description: "Iniciar Key Atlas y abrir configuración"; Flags: nowait postinstall skipifsilent
