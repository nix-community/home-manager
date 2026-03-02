{ lib, ... }:
let
  modulePath = [
    "programs"
    "vscode"
  ];

  mkVscodeModule = import ./mkVscodeModule.nix;
in
{
  imports = [
    (mkVscodeModule {
      inherit modulePath;
      name = "Visual Studio Code";
      packageName = "vscode";
      knownProducts = {
        cursor = {
          dataFolderName = ".cursor";
          nameShort = "Cursor";
        };
        kiro = {
          dataFolderName = ".kiro";
          nameShort = "Kiro";
        };
        openvscode-server = {
          dataFolderName = ".openvscode-server";
          nameShort = "OpenVSCode Server";
        };
        vscode = {
          dataFolderName = ".vscode";
          nameShort = "Code";
        };
        vscode-insiders = {
          dataFolderName = ".vscode-insiders";
          nameShort = "Code - Insiders";
        };
        vscodium = {
          dataFolderName = ".vscode-oss";
          nameShort = "VSCodium";
        };
        windsurf = {
          dataFolderName = ".windsurf";
          nameShort = "Windsurf";
        };
        antigravity = {
          dataFolderName = ".antigravity";
          nameShort = "Antigravity";
        };
      };
      pnamesSkipVersionCheck = [
        "cursor"
        "windsurf"
        "antigravity"
      ];
      visible = true;
    })

    ./haskell.nix

    (lib.mkChangedOptionModule
      [
        "programs"
        "vscode"
        "immutableExtensionsDir"
      ]
      [ "programs" "vscode" "mutableExtensionsDir" ]
      (config: !config.programs.vscode.immutableExtensionsDir)
    )
  ]
  ++
    map
      (
        v:
        lib.mkRenamedOptionModule
          [ "programs" "vscode" v ]
          [
            "programs"
            "vscode"
            "profiles"
            "default"
            v
          ]
      )
      [
        "enableUpdateCheck"
        "enableExtensionUpdateCheck"
        "userSettings"
        "userTasks"
        "userMcp"
        "keybindings"
        "extensions"
        "languageSnippets"
        "globalSnippets"
      ];
}
