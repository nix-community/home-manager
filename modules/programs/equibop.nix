{ lib, ... }:
let
  mkVesktopLikeModule = import ./vesktop/mkVesktopLikeModule.nix;
in
{
  imports = [
    (mkVesktopLikeModule {
      moduleName = "equibop";
      cordModuleName = "equicord";
      allConfigOptionsLink = "https://github.com/Equicord/Equibop/blob/main/src/shared/settings.d.ts";
      allCordConfigOptionsLink = "https://github.com/Equicord/Equicord/blob/main/src/api/Settings.ts";
      installPackage = true;
      maintainers = with lib.maintainers; [
        PerchunPak
        NotAShelf
      ];
    })
  ];
}
