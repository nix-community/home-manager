{ lib, ... }:

{
  meta.maintainers = [ lib.maintainers.hectorgray ];

  imports = [
    (import ./vscode/mkVscodeModule.nix {
      modulePath = [
        "programs"
        "positron"
      ];

      name = "Positron";
      packageName = "positron-bin";
      nameShort = "Positron";
      dataFolderName = ".positron";
      skipVersionCheck = true;
    })
  ];
}
