{ lib, ... }:
let
  modulePath = [
    "programs"
    "antigravity"
  ];

  mkVscodeModule = import ./vscode/mkVscodeModule.nix;
in
{
  meta.maintainers = with lib.maintainers; [ sei40kr ];

  imports = [
    (mkVscodeModule {
      inherit modulePath;
      name = "Antigravity";
      packageName = "antigravity";
      nameShort = "Antigravity";
      dataFolderName = ".antigravity";
      skipVersionCheck = true;
    })
  ];
}
