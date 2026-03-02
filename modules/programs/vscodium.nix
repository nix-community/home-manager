{ ... }:
let
  modulePath = [
    "programs"
    "vscodium"
  ];

  mkVscodeModule = import ./vscode/mkVscodeModule.nix;
in
{
  imports = [
    (mkVscodeModule {
      inherit modulePath;
      name = "VSCodium";
      packageName = "vscodium";
      visible = true;
    })
  ];
}
