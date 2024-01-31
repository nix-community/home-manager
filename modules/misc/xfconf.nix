{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xfconf;

  xfIntVariant = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "int" "uint" "uint64" ];
        description = ''
          To distinguish between int, uint and uint64 in xfconf,
          you can specify the type in xfconf with this submodule.
          For other types, you don't need to use this submodule,
          just specify the value is enough.
        '';
      };
      value = mkOption {
        type = types.int;
        description = "The value in xfconf.";
      };
    };
  };

  withType = v:
    if builtins.isAttrs v then [
      "-t"
      v.type
      "-s"
      (toString v.value)
    ] else if builtins.isBool v then [
      "-t"
      "bool"
      "-s"
      (if v then "true" else "false")
    ] else if builtins.isInt v then [
      "-t"
      "int"
      "-s"
      (toString v)
    ] else if builtins.isFloat v then [
      "-t"
      "double"
      "-s"
      (toString v)
    ] else if builtins.isString v then [
      "-t"
      "string"
      "-s"
      v
    ] else if builtins.isList v then
      [ "-a" ] ++ concatMap withType v
    else
      throw "unexpected xfconf type: ${builtins.typeOf v}";

in {
  meta.maintainers = [ maintainers.chuangzhu ];

  options.xfconf = {
    enable = mkOption {
      type = types.bool;
      default = true;
      visible = false;
      description = ''
        Whether to enable Xfconf settings.

        Note, if you use NixOS then you must add
        `programs.xfconf.enable = true`
        to your system configuration. Otherwise you will see a systemd error
        message when your configuration is activated.
      '';
    };

    settings = mkOption {
      type = with types;
      # xfIntVariant must come AFTER str; otherwise strings are treated as submodule imports...
        let value = nullOr (oneOf [ bool int float str xfIntVariant ]);
        in attrsOf (attrsOf (either value (listOf value))) // {
          description = "xfconf settings";
        };
      default = { };
      example = literalExpression ''
        {
          xfce4-session = {
            "startup/ssh-agent/enabled" = false;
            "general/LockCommand" = "''${pkgs.lightdm}/bin/dm-tool lock";
          };
          xfce4-desktop = {
            "backdrop/screen0/monitorLVDS-1/workspace0/last-image" =
              "''${pkgs.nixos-artwork.wallpapers.stripes-logo.gnomeFilePath}";
          };
        }
      '';
      description = ''
        Settings to write to the Xfconf configuration system.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.settings != { }) {
    assertions =
      [ (hm.assertions.assertPlatform "xfconf" pkgs platforms.linux) ];

    home.activation.xfconfSettings = hm.dag.entryAfter [ "installPackages" ]
      (let
        mkCommand = channel: property: value: ''
          run ${pkgs.xfce.xfconf}/bin/xfconf-query \
            ${
              escapeShellArgs ([ "-c" channel "-p" "/${property}" ]
                ++ (if value == null then
                  [ "-r" ]
                else
                  [ "-n" ] ++ withType value))
            }
        '';

        commands = mapAttrsToList
          (channel: properties: mapAttrsToList (mkCommand channel) properties)
          cfg.settings;

        load = pkgs.writeShellScript "load-xfconf" ''
          ${config.lib.bash.initHomeManagerLib}
          ${concatMapStrings concatStrings commands}
        '';
      in ''
        if [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
          export DBUS_RUN_SESSION_CMD=""
        else
          export DBUS_RUN_SESSION_CMD="${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon"
        fi

        run $DBUS_RUN_SESSION_CMD ${load}

        unset DBUS_RUN_SESSION_CMD
      '');
  };
}
