{ lib, ... }:
let
  modulePath = [
    "programs"
    "windsurf"
  ];

  mkVscodeModule = import ./vscode/mkVscodeModule.nix;
in
{
  meta.maintainers = with lib.maintainers; [ sei40kr ];

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
