{
  config,
  pkgs,
  lib,
  ...
}:

let

  cfg = config.programs.hyprland-qt-support;

in
{
  meta.maintainers = with lib.maintainers; [ ReStranger ];

  options.programs.hyprland-qt-support = {
    enable = lib.mkEnableOption "" // {
      description = ''
        Whether to enable Hyprland Qt support, a Qt6 QML style provider for hypr* apps.
      '';
    };

    package = lib.mkPackageOption pkgs "hyprland-qt-support" { nullable = true; };

    settings = lib.mkOption {
      type =
        with lib.types;
        let
          valueType =
            nullOr (oneOf [
              bool
              int
              float
              str
              path
              (attrsOf valueType)
              (listOf valueType)
            ])
            // {
              description = "Hyprland configuration value";
            };
        in
        valueType;
      default = { };
      example = lib.literalExpression ''
        {
          roundness = 1;
          border_width = 1;
          reduce_motion = false;
        }
      '';
      description = ''
        Hyprland Qt Support configuration written in Nix. See
        <https://wiki.hypr.land/Hypr-Ecosystem/hyprland-qt-support/> for more
        examples.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.hyprland-qt-support" pkgs lib.platforms.linux)
    ];
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."hypr/application-style.conf" = lib.mkIf (cfg.settings != { }) {
      text = lib.hm.generators.toHyprconf { attrs = cfg.settings; };
    };
  };
}
