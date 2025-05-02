{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.services.mako;

  generateConfig = lib.generators.toKeyValue { };
in
{
  meta.maintainers = [ lib.maintainers.onny ];

  imports = [
    (lib.mkRenamedOptionModule [ "programs" "mako" ] [ "services" "mako" ])

    (lib.mkRemovedOptionModule [
      "services"
      "mako"
      "extraConfig"
    ] "Use services.mako.settings instead.")

    (lib.mkRenamedOptionModule
      [ "services" "mako" "maxVisible" ]
      [ "services" "mako" "settings" "maxVisible" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "mako" "maxHistory" ]
      [ "services" "mako" "settings" "maxHistory" ]
    )
    (lib.mkRenamedOptionModule [ "services" "mako" "sort" ] [ "services" "mako" "settings" "sort" ])
    (lib.mkRenamedOptionModule [ "services" "mako" "output" ] [ "services" "mako" "settings" "output" ])
    (lib.mkRenamedOptionModule [ "services" "mako" "layer" ] [ "services" "mako" "settings" "layer" ])
    (lib.mkRenamedOptionModule [ "services" "mako" "anchor" ] [ "services" "mako" "settings" "anchor" ])
    (lib.mkRenamedOptionModule [ "services" "mako" "font" ] [ "services" "mako" "settings" "font" ])
    (lib.mkRenamedOptionModule
      [ "services" "mako" "backgroundColor" ]
      [ "services" "mako" "settings" "backgroundColor" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "mako" "textColor" ]
      [ "services" "mako" "settings" "textColor" ]
    )
    (lib.mkRenamedOptionModule [ "services" "mako" "width" ] [ "services" "mako" "settings" "width" ])
    (lib.mkRenamedOptionModule [ "services" "mako" "height" ] [ "services" "mako" "settings" "height" ])
    (lib.mkRenamedOptionModule [ "services" "mako" "margin" ] [ "services" "mako" "settings" "margin" ])
    (lib.mkRenamedOptionModule
      [ "services" "mako" "padding" ]
      [ "services" "mako" "settings" "padding" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "mako" "borderSize" ]
      [ "services" "mako" "settings" "borderSize" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "mako" "borderColor" ]
      [ "services" "mako" "settings" "borderColor" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "mako" "borderRadius" ]
      [ "services" "mako" "settings" "borderRadius" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "mako" "progressColor" ]
      [ "services" "mako" "settings" "progressColor" ]
    )
    (lib.mkRenamedOptionModule [ "services" "mako" "icons" ] [ "services" "mako" "settings" "icons" ])
    (lib.mkRenamedOptionModule
      [ "services" "mako" "maxIconSize" ]
      [ "services" "mako" "settings" "maxIconSize" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "mako" "iconPath" ]
      [ "services" "mako" "settings" "iconPath" ]
    )
    (lib.mkRenamedOptionModule [ "services" "mako" "markup" ] [ "services" "mako" "settings" "markup" ])
    (lib.mkRenamedOptionModule
      [ "services" "mako" "actions" ]
      [ "services" "mako" "settings" "actions" ]
    )
    (lib.mkRenamedOptionModule [ "services" "mako" "format" ] [ "services" "mako" "settings" "format" ])
    (lib.mkRenamedOptionModule
      [ "services" "mako" "defaultTimeout" ]
      [ "services" "mako" "settings" "defaultTimeout" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "mako" "ignoreTimeout" ]
      [ "services" "mako" "settings" "ignoreTimeout" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "mako" "groupBy" ]
      [ "services" "mako" "settings" "groupBy" ]
    )
  ];

  options.services.mako = {
    enable = mkEnableOption "mako";
    package = mkPackageOption pkgs "mako" { };
    settings = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = ''
        {
          actions = "true";
          anchor = "top-right";
          backgroundColor = "#000000";
          borderColor = "#FFFFFF";
          borderRadius = "0";
          defaultTimeout = "0";
          font = "monospace 10";
          height = "100";
          width = "300";
          icons = "true";
          ignoreTimeout = "false";
          layer = "top";
          margin = "10";
          markup = "true";
        }
      '';
      description = ''
        Configuration settings for mako. All available options can be found
        here: <https://github.com/emersion/mako/blob/master/doc/mako.5.scd>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mako" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."mako/config" = mkIf (cfg.settings != { }) {
      onChange = "${cfg.package}/bin/makoctl reload || true";
      text = generateConfig cfg.settings;
    };
  };
}
