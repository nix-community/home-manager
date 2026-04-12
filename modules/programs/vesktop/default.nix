{ lib, config, ... }:
let
  mkVesktopLikeModule = import ./mkVesktopLikeModule.nix;
  cfg = config.programs.vesktop;
in
{
  imports = [
    (mkVesktopLikeModule {
      moduleName = "vesktop";
      cordModuleName = "vencord";
      allConfigOptionsLink = "https://github.com/Vencord/Vesktop/blob/main/src/shared/settings.d.ts";
      allCordConfigOptionsLink = "https://github.com/Vendicated/Vencord/blob/main/src/api/Settings.ts";
      installPackage = false;
      maintainers = with lib.maintainers; [
        Flameopathic
        LilleAila
      ];
    })
  ];

  options.programs.vesktop = {
    vencord.useSystem = lib.mkEnableOption "Vencord package from Nixpkgs";
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [
      (cfg.package.override { withSystemVencord = cfg.vencord.useSystem; })
    ];
  };
}
