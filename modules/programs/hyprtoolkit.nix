{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.hyprtoolkit;
in
{
  meta.maintainers = [ lib.hm.maintainers.rachitvrma ];

  options.programs.hyprtoolkit = {
    enable = lib.mkEnableOption ''
      A GUI toolkit for developing applications that run natively on Wayland.
      It’s specifically made for Hyprland’s needs, but will generally run on
      any Wayland compositor that supports modern standards.
    '';
    package = lib.mkPackageOption pkgs "hyprtoolkit" { nullable = true; };
    settings = lib.mkOption {
      type =
        with lib.types;
        let
          valueType =
            nullOr (oneOf [
              int
              str
              (attrsOf valueType)
              (listOf valueType)
            ])
            // {
              description = "Hyprtoolkit configuration values";
            };
        in
        valueType;
      default = { };
      example = {
        background = "0xFF181818";
        base = "0xFF202020";
        h1_size = 19;
        h2_size = 15;
      };
      description = ''
        The configuration written to {file}`$XDG_CONFIG_HOME/hypr/hyprtoolkit.conf`.
        More options can be found here: <https://wiki.hypr.land/Hypr-Ecosystem/hyprtoolkit/>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.hyprtoolkit" pkgs lib.platforms.linux)
    ];
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."hypr/hyprtoolkit.conf" = lib.mkIf (cfg.settings != { }) {
      text = lib.hm.generators.toHyprconf { attrs = cfg.settings; };
    };
  };
}
