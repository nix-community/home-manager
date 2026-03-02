{ ... }:
let
  modulePath = [
    "programs"
    "antigravity"
  ];

  mkVscodeModule = import ./vscode/mkVscodeModule.nix;
in
{
  imports = [
    (mkVscodeModule {
      inherit modulePath;
      name = "Antigravity";
      packageName = "antigravity";
      visible = true;
    })
  ];
}
