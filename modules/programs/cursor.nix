{ ... }:
let
  modulePath = [
    "programs"
    "cursor"
  ];

  mkVscodeModule = import ./vscode/mkVscodeModule.nix;
in
{
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
