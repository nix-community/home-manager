{ ... }:
let
  modulePath = [
    "programs"
    "kiro"
  ];

  mkVscodeModule = import ./vscode/mkVscodeModule.nix;
in
{
  imports = [
    (mkVscodeModule {
      inherit modulePath;
      name = "Kiro";
      packageName = "kiro";
      nameShort = "Kiro";
      dataFolderName = ".kiro";
      visible = true;
    })
  ];
}
