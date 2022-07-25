{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.sunpaper;
  newDerivation = (pkgs.sunpaper.overrideAttrs (previousAttrs: {
    postPatch = concatStrings [
      previousAttrs.postPatch
      ''
        substituteInPlace sunpaper.sh \
          --replace "38.9072N" ${cfg.latitude} \
          --replace "77.0369W" ${cfg.longitude} \
          --replace "Corporate-Synergy" "${cfg.wallpaper_collection}"
      ''
    ];
  }));
in {
  meta.maintainers = [ hm.maintainers.jevy ];
  config = mkIf cfg.enable {

    home.packages = [ newDerivation ];

    systemd.user.services.sunpaper = {
      Unit = {
        Description =
          "A utility to change wallpaper based on local weather, sunrise and sunset times.";
        WantedBy = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = ''
          ${newDerivation}/bin/sunpaper -d
        '';
        RestartSec = 3;
        Restart = "always";
      };
    };
  };

  options.programs.sunpaper = {

    enable = mkEnableOption
      "Sunpaper, a utility to change wallpaper based on local weather, sunrise and sunset times";

    wallpaper_collection = mkOption {
      type = types.str;
      default = "Corporate-Synergy";
      example = "Corporate-Synergy";
      description = ''
        Wallpaper collection Sunpaper will use for your background. Check sunpaper's image repository (<link xlink:href="https://github.com/hexive/sunpaper/tree/main/images" />) for out-of-the-box options.
      '';
    };

    latitude = mkOption {
      type = types.str;
      description = ''
        Your current latitude in format ##.##D where D is N or S
      '';
    };

    longitude = mkOption {
      type = types.str;
      description = ''
        Your current longitude in format ##.##D where D is E or W
      '';
    };

  };
}
