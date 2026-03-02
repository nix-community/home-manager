{ lib, ... }:
let
  modulePath = [
    "programs"
    "kiro"
  ];

  mkVscodeModule = import ./vscode/mkVscodeModule.nix;
in
{
  meta.maintainers = with lib.maintainers; [ sei40kr ];

  imports = [
    (mkVscodeModule {
      inherit modulePath;
      name = "Kiro";
      packageName = "kiro";
      nameShort = "Kiro";
      dataFolderName = ".kiro";
    })
  ];
}
