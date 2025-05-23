{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) types;

  boolTrue = {
    type = types.bool;
    default = true;
  };

  number0 = {
    type = types.int;
    default = 0;
  };

  knownSettings = {
    edge = {
      type = types.enum [
        "left"
        "right"
        "top"
        "bottom"
        "none"
      ];
      default = "bottom";
    };

    align = {
      type = types.enum [
        "left"
        "right"
        "center"
      ];
      default = "center";
    };

    margin = number0;
    widthtype = {
      type = types.enum [
        "request"
        "pixel"
        "percent"
      ];
      default = "percent";
    };

    width = {
      type = types.int;
      default = 100;
    };

    heighttype = {
      type = types.enum [
        "request"
        "pixel"
      ];
      default = "pixel";
    };

    height = {
      type = types.int;
      default = 26;
    };

    SetDockType = boolTrue;

    SetPartialStrut = boolTrue;

    transparent = {
      type = types.bool;
      default = false;
    };

    alpha = {
      type = types.int;
      default = 127;
    };

    tint = {
      type = types.str;
      default = "0xFFFFFFFF";
    };

    distance = number0;

    distancefrom = {
      type = types.enum [
        "left"
        "right"
        "top"
        "bottom"
      ];
      default = "top";
    };

    expand = boolTrue;

    padding = number0;

    monitor = {
      type = types.either types.ints.unsigned (types.enum [ "primary" ]);
      default = 0;
    };

    iconspacing = number0;
  };

  cfg = config.services.trayer;

in
{
  meta.maintainers = [ lib.hm.maintainers.mager ];

  options = {
    services.trayer = {
      enable = lib.mkEnableOption "trayer, the lightweight GTK2+ systray for UNIX desktops";

      package = lib.mkPackageOption pkgs "trayer" { };

      settings = lib.mkOption {
        type = with types; attrsOf (nullOr (either str (either bool int)));
        description = ''
          Trayer configuration as a set of attributes. Further details can be
          found in [trayer's README](https://github.com/sargon/trayer-srg/blob/master/README).

          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (n: v: ''
              {var}`${n}`
              : ${v.type.description} (default: `${builtins.toJSON v.default}`)
            '') knownSettings
          )}
        '';
        default = { };
        example = lib.literalExpression ''
          {
            edge = "top";
            padding = 6;
            SetDockType = true;
            tint = "0x282c34";
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.trayer" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.trayer =
      let
        valueToString = v: if lib.isBool v then (if v then "true" else "false") else "${toString v}";
        parameter = k: v: "--${k} ${valueToString v}";
        parameters = lib.concatStringsSep " " (lib.mapAttrsToList parameter cfg.settings);
      in
      {
        Unit = {
          Description = "trayer -- lightweight GTK2+ systray for UNIX desktops";
          PartOf = [ "tray.target" ];
        };

        Install.WantedBy = [ "tray.target" ];

        Service = {
          ExecStart = "${cfg.package}/bin/trayer ${parameters}";
          Restart = "on-failure";
        };
      };
  };
}
