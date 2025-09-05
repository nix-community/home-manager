{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.yofi;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.yofi = {
    enable = mkEnableOption "yofi";
    package = mkPackageOption pkgs "yofi" { nullable = true; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        width = 400;
        height = 512;
        force_window = false;
        corner_radius = "0";
        font_size = 24;
        bg_color = "0x272822ee";
        bg_border_color = "0x131411ff";
        input_text = {
          font_color = "0xf8f8f2ff";
          bg_color = "0x75715eff";
          margin = "5";
          padding = "1.7 -4";
        };
      };
      description = ''
        Configuration settings for yofi. For all the available options
        see: <https://github.com/l4l/yofi/wiki/Configuration#main-configuration>
      '';
    };
    blacklist = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [
        "firefox"
        "librewolf"
        "com.obsproject.Studio"
        "com.rtosta.zapzap"
        "cups"
        "kitty-open"
        "nvim"
      ];
      description = ''
        List of .desktop files yofi should ignore.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.yofi" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile = {
      "yofi/yofi.config" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "yofi-config" cfg.settings;
      };
      "yofi/blacklist" = mkIf (cfg.blacklist != [ ]) {
        text = concatStringsSep "\n" (map (x: x + ".desktop") cfg.blacklist);
      };
    };
  };
}
