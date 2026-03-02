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
