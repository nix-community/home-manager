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
      packageName = "code-cursor";
      nameShort = "Cursor";
      dataFolderName = ".cursor";
    })
  ];
}
