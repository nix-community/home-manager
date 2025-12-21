{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.sunpaper;
  keyValue = pkgs.formats.keyValue { };
in
{
  meta.maintainers = [ lib.hm.maintainers.strangeoceans ];

  options.programs.sunpaper = {
    enable = lib.mkEnableOption "Sunpaper";
    package = lib.mkPackageOption pkgs "sunpaper" { nullable = true; };
    latitude = lib.mkOption {
      type = lib.types.str;
      example = "38.9072N";
      description = "Latitude for sun calculations.";
    };
    longitude = lib.mkOption {
      type = lib.types.str;
      example = "77.0369W";
      description = "Longitude for sun calculations.";
    };
    wallpaperPath = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to wallpaper theme directory. Should contain 8 jpg images with
        numbered filenames (i.e. 1.jpg, 2.jpg, ..., 8.jpg) corresponding to the
        following: (1) Night, (2) Early sunrise, (3) Mid sunrise, (4) Late
        sunrise, (5) Daylight, (6) Early twilight, (7) Mid twilight, (8) Late
        twilight. See <https://github.com/hexive/sunpaper/tree/main/images>
      '';
    };
    wallpaperMode = lib.mkOption {
      type = lib.types.enum [
        "stretch"
        "center"
        "tile"
        "scale"
        "zoom"
        "fill"
      ];
      example = "scale";
      description = ''
        How wallpaper should be fit to screen.
      '';
    };
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      example = lib.literalExpression ''
        {
          cachePath = "/tmp"
        }
      '';
      description = ''
        Additional config options. See <https://github.com/hexive/sunpaper/blob/main/sunpaper.sh>."
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.sunpaper" pkgs lib.platforms.linux)
    ];
    home.packages = lib.optionals (cfg.package != null) [ cfg.package ];

    xdg.configFile."sunpaper/config".source = keyValue.generate "sunpaper-config" (
      {
        inherit (cfg)
          latitude
          longitude
          wallpaperMode
          ;
        wallpaperPath = "${cfg.wallpaperPath}";
      }
      // cfg.extraConfig
    );
  };
}
