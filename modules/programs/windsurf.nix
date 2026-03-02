{ ... }:
let
  modulePath = [
    "programs"
    "windsurf"
  ];

  mkVscodeModule = import ./vscode/mkVscodeModule.nix;
in
{
  imports = [
    (mkVscodeModule {
      inherit modulePath;
      name = "Windsurf";
      packageName = "windsurf";
      nameShort = "Windsurf";
      dataFolderName = ".windsurf";
    })
  ];
}
