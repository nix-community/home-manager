{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xfconf;

  withType = v:
    if builtins.isBool v then [
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
        </para><para>
        Note, if you use NixOS then you must add
        <code>programs.xfconf.enable = true</code>
        to your system configuration. Otherwise you will see a systemd error
        message when your configuration is activated.
      '';
    };

    settings = mkOption {
      type = with types;
        attrsOf (attrsOf (oneOf [
          bool
          int
          float
          str
          (listOf (oneOf [ bool int float str ]))
        ])) // {
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
          $DRY_RUN_CMD ${pkgs.xfce.xfconf}/bin/xfconf-query \
            ${
              escapeShellArgs
              ([ "-n" "-c" channel "-p" "/${property}" ] ++ withType value)
            }
        '';

        commands = mapAttrsToList
          (channel: properties: mapAttrsToList (mkCommand channel) properties)
          cfg.settings;

        load = pkgs.writeShellScript "load-xfconf"
          (concatMapStrings concatStrings commands);
      in ''
        if [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
          export DBUS_RUN_SESSION_CMD=""
        else
          export DBUS_RUN_SESSION_CMD="${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon"
        fi

        $DRY_RUN_CMD $DBUS_RUN_SESSION_CMD ${load}

        unset DBUS_RUN_SESSION_CMD
      '');
  };
}
