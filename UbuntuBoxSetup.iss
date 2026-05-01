; UbuntuBox - Inno Setup Installer Script
; Requires: Inno Setup 6+

#define MyAppName "UbuntuBox"
#define MyAppVersion "2.0"
#define MyAppPublisher "Hashim Hilal"
#define MyAppURL "https://github.com/"
#define MyAppExeName "UbuntuBox.bat"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\UbuntuBox
DefaultGroupName={#MyAppName}
AllowNoIcons=no
OutputBaseFilename=UbuntuBoxSetup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
MinVersion=10.0.19041
SetupIconFile=icon.ico
UninstallDisplayIcon={app}\icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "vscodeintegration"; Description: "Add UbuntuBox as VS Code terminal (UbuntuBox (WSL))"; GroupDescription: "VS Code Integration:"; Flags: checkedonce

[Files]
Source: "Launch-UbuntuBox.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Launch-UbuntuBox-VSCode.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "UbuntuBox.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "ubuntu-box.tar"; DestDir: "{app}"; Flags: ignoreversion
Source: "AddVSCodeTerminal.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "UninstallImage.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "UninstallVSCode.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "podman-installer.exe"; DestDir: "{tmp}"; Flags: ignoreversion deleteafterinstall
Source: "EnableFeatures.ps1"; DestDir: "{tmp}"; Flags: ignoreversion deleteafterinstall
Source: "InitPodman.ps1"; DestDir: "{tmp}"; Flags: ignoreversion deleteafterinstall
Source: "LoadImage.ps1"; DestDir: "{tmp}"; Flags: ignoreversion deleteafterinstall

[Icons]
Name: "{group}\UbuntuBox"; Filename: "{app}\UbuntuBox.bat"; IconFilename: "{app}\icon.ico"
Name: "{group}\Uninstall UbuntuBox"; Filename: "{uninstallexe}"
Name: "{group}\Add UbuntuBox to VS Code Terminal"; Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\AddVSCodeTerminal.ps1"""; IconFilename: "{app}\icon.ico"
Name: "{commondesktop}\UbuntuBox"; Filename: "{app}\UbuntuBox.bat"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{tmp}\EnableFeatures.ps1"""; Flags: runhidden waituntilterminated; StatusMsg: "Checking Windows features..."
Filename: "{tmp}\podman-installer.exe"; Parameters: "/quiet /norestart"; Flags: waituntilterminated; StatusMsg: "Installing Podman..."
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{tmp}\InitPodman.ps1"""; Flags: runhidden waituntilterminated; StatusMsg: "Initializing Podman machine..."
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{tmp}\LoadImage.ps1"" ""{app}"""; Flags: runhidden waituntilterminated; StatusMsg: "Loading Ubuntu container image..."
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\AddVSCodeTerminal.ps1"""; Flags: runhidden waituntilterminated; StatusMsg: "Adding UbuntuBox to VS Code terminal..."; Tasks: vscodeintegration
Filename: "{app}\UbuntuBox.bat"; Flags: nowait postinstall skipifsilent; Description: "Launch UbuntuBox now"

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\UninstallImage.ps1"""; Flags: runhidden waituntilterminated; RunOnceId: "RemoveUbuntuBoxImage"
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\UninstallVSCode.ps1"""; Flags: runhidden waituntilterminated; RunOnceId: "RemoveVSCodeProfile"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
var
  RebootNeeded: Boolean;

function InitializeSetup(): Boolean;
begin
  Result := True;
  RebootNeeded := False;
  if not (GetWindowsVersion >= $0A003905) then begin
    MsgBox('UbuntuBox requires Windows 10 v2004 or later.' + #13#10 + 'Please update Windows and try again.', mbError, MB_OK);
    Result := False;
    Exit;
  end;
end;

function NeedRestart(): Boolean;
begin
  Result := RebootNeeded;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Msg: String;
begin
  if CurStep = ssPostInstall then
  begin
    if not FileExists(ExpandConstant('{tmp}\features_ok.txt')) then
    begin
      RebootNeeded := True;
      Msg := 'UbuntuBox enabled required Windows features:' + #13#10 + #13#10;
      Msg := Msg + '  - Windows Subsystem for Linux (WSL2)' + #13#10;
      Msg := Msg + '  - Virtual Machine Platform' + #13#10 + #13#10;
      Msg := Msg + 'A restart is required before UbuntuBox can be used.' + #13#10 + #13#10;
      Msg := Msg + 'After restarting, run the installer again to complete setup.';
      MsgBox(Msg, mbInformation, MB_OK);
    end;
  end;
end;
