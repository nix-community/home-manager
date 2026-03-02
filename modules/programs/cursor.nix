{ lib, ... }:
let
  modulePath = [
    "programs"
    "cursor"
  ];

  mkVscodeModule = import ./vscode/mkVscodeModule.nix;
in
{
  meta.maintainers = with lib.maintainers; [ sei40kr ];

  imports = [
    (mkVscodeModule {
      inherit modulePath;
      name = "Cursor";
      packageName = "cursor";
      nameShort = "Cursor";
      dataFolderName = ".cursor";
    })
  ];
}
