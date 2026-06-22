{ lib, ... }:
let
  modulePath = [
    "programs"
    "vscodium"
  ];

  mkVscodeModule = import ./vscode/mkVscodeModule.nix;
in
{
  meta.maintainers = with lib.maintainers; [ sei40kr ];

  imports = [
    (mkVscodeModule {
      inherit modulePath;
      name = "VSCodium";
      packageName = "vscodium";
      nameShort = "VSCodium";
      dataFolderName = ".vscode-oss";
    })
  ];
}
