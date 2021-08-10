{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.fnott;

  concatStringsSep' = sep: list:
    concatStringsSep sep (filter (str: str != "") list);

  mkKeyValue = generators.mkKeyValueDefault { } "=";
  genINI = generators.toINI { };

  iniFormatType = with types;
    let
      iniAtom = types.nullOr (types.oneOf [ bool int float str ]) // {
        description = "INI atom (null, bool, int, float or string)";
      };
    in attrsOf (attrsOf iniAtom);
in {
  options = {
    services.fnott = {
      enable = mkEnableOption ''
        fnott, a lightweight Wayland notification daemon for wlroots-based compositors
      '';

      package = mkOption {
        type = types.package;
        default = pkgs.fnott;
        defaultText = literalExample "pkgs.fnott";
        description = "Package providing <command>fnott</command>.";
      };

      configFile = mkOption {
        type = types.either types.str types.path;
        default = "${config.xdg.configHome}/fnott/fnott.ini";
        defaultText = "$XDG_CONFIG_HOME/fnott/fnott.ini";
        description = ''
          Path to the configuration file read by fnott.
          </para><para>
          Note that environment variables in the path won't be properly expanded.
          </para><para>
          The configuration specified under 
          <option>services.fnott.settings</option> will be generated and
          written to <filename>$XDG_CONFIG_HOME/fnott/fnott.ini</filename>
          regardless of this option. This allows using a mutable configuration file
          generated from the immutable one, useful in scenarios where live reloading is desired.
        '';
      };

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "-s" ];
        description = ''
          Extra arguments to use for executing fnott.
        '';
      };

      settings = mkOption {
        type = iniFormatType;
        default = { };
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/fnott/fnott.ini</filename>.
          </para><para>
          See
          <citerefentry>
            <refentrytitle>fnott.ini</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry> for a list of avaliable options and <link
          xlink:href="https://codeberg.org/dnkl/fnott/src/branch/master/fnott.ini"/>
          for an example configuration.
        '';
        example = literalExample ''
          {
            main = {
              notification-margin = 5;
            };

            low = {
              timeout = 5;
              title-font = "Dina:weight=bold:slant=italic";
              title-color = "ffffff";
            };
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "services.fnott" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    systemd.user.services.fnott = {
      Unit = {
        Description = "Fnott notification daemon";
        Documentation = "man:fnott(1)";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = concatStringsSep' " " [
          "${cfg.package}/bin/fnott -c ${cfg.configFile}"
          (escapeShellArgs cfg.extraFlags)
        ];
      };
    };

    # FIXME: Remove after next version release (https://codeberg.org/dnkl/fnott/pulls/24).
    xdg.configFile."fnott/fnott.ini" = mkIf (cfg.settings != { }) (mkMerge [
      { text = genINI cfg.settings; }
      (mkIf (cfg.settings ? main) {
        text = mkForce (concatStringsSep' "\n" [
          ''
            ${concatStringsSep "\n"
            (mapAttrsToList mkKeyValue cfg.settings.main)}
          ''
          (genINI (removeAttrs cfg.settings [ "main" ]))
        ]);
      })
    ]);
  };
}
