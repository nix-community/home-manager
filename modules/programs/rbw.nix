{ config, lib, pkgs, ... }:
let
  cfg = config.programs.rbw;

  jsonFormat = pkgs.formats.json { };

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  settingsModule = with lib;
    types.submodule {
      freeformType = jsonFormat.type;
      options = {
        email = mkOption {
          type = types.str;
          example = "name@example.com";
          description = "The email address for your bitwarden account.";
        };

        base_url = mkOption {
          type = with types; nullOr str;
          default = null;
          example = "bitwarden.example.com";
          description =
            "The base-url for a self-hosted bitwarden installation.";
        };

        identity_url = mkOption {
          type = with types; nullOr str;
          default = null;
          example = "identity.example.com";
          description = "The identity url for your bitwarden installation.";
        };

        lock_timeout = mkOption {
          type = types.ints.unsigned;
          default = 3600;
          example = 300;
          description = ''
            The amount of time that your login information should be cached.
          '';
        };

        pinentry = mkOption {
          type = with types; either package (enum pkgs.pinentry.flavors);
          example = "gnome3";
          default = "gtk2";
          description = ''
            Which pinentry interface to use. Beware that
            <literal>pinentry-gnome3</literal> may not work on non-Gnome
            systems. You can fix it by adding the following to your
            system configuration:
            <programlisting language="nix">
            services.dbus.packages = [ pkgs.gcr ];
            </programlisting>
            For this reason, the default is <literal>gtk2</literal> for
            now.
          '';
          # we want the program in the config
          apply = val:
            if builtins.isString val then
              "${pkgs.pinentry.${val}}/bin/pinentry"
            else
              "${val}/${val.binaryPath or "bin/pinentry"}";
        };
      };
    };
in {
  meta.maintainers = with lib.hm.maintainers; [ ambroisie ];

  options.programs.rbw = with lib; {
    enable = mkEnableOption "rwb, a CLI Bitwarden client";

    package = mkOption {
      type = types.package;
      default = pkgs.rbw;
      defaultText = literalExpression "pkgs.rbw";
      description = ''
        Package providing the <command>rbw</command> tool and its
        <command>rbw-agent</command> daemon.
      '';
    };

    settings = mkOption {
      type = types.nullOr settingsModule;
      default = null;
      example = literalExpression ''
        {
          email = "name@example.com";
          lock_timeout = 300;
          pinentry = "gnome3";
        }
      '';
      description = ''
        rbw configuration, if not defined the configuration will not be
        managed by Home Manager.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [ cfg.package ];
    }

    # Only manage configuration if not empty
    (lib.mkIf (cfg.settings != null && !isDarwin) {
      xdg.configFile."rbw/config.json".source =
        jsonFormat.generate "rbw-config.json" cfg.settings;
    })

    (lib.mkIf (cfg.settings != null && isDarwin) {
      home.file."Library/Application Support/rbw/config.json".source =
        jsonFormat.generate "rbw-config.json" cfg.settings;
    })
  ]);
}
