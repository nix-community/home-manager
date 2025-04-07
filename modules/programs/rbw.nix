{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rbw;

  jsonFormat = pkgs.formats.json { };

  inherit (lib) mkOption types;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  settingsModule = types.submodule {
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
        example = "https://bitwarden.example.com/";
        description = "The base-url for a self-hosted bitwarden installation.";
      };

      identity_url = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "https://identity.example.com/";
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
        type = types.nullOr types.package;
        example = lib.literalExpression "pkgs.pinentry-gnome3";
        default = null;
        description = ''
          Which pinentry interface to use. Beware that
          `pinentry-gnome3` may not work on non-Gnome
          systems. You can fix it by adding the following to your
          system configuration:
          ```nix
          services.dbus.packages = [ pkgs.gcr ];
          ```
        '';
        # we want the program in the config
        apply = val: if val == null then val else lib.getExe val;
      };
    };
  };
in
{
  meta.maintainers = with lib.hm.maintainers; [ ambroisie ];

  options.programs.rbw = {
    enable = lib.mkEnableOption "rbw, a CLI Bitwarden client";

    package = lib.mkPackageOption pkgs "rbw" {
      extraDescription = ''
        Package providing the {command}`rbw` tool and its
        {command}`rbw-agent` daemon.
      '';
    };

    settings = mkOption {
      type = types.nullOr settingsModule;
      default = null;
      example = lib.literalExpression ''
        {
          email = "name@example.com";
          lock_timeout = 300;
          pinentry = pkgs.pinentry-gnome3;
        }
      '';
      description = ''
        rbw configuration, if not defined the configuration will not be
        managed by Home Manager.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];
      }

      # Only manage configuration if not empty
      (lib.mkIf (cfg.settings != null && !isDarwin) {
        xdg.configFile."rbw/config.json".source = jsonFormat.generate "rbw-config.json" cfg.settings;
      })

      (lib.mkIf (cfg.settings != null && isDarwin) {
        home.file."Library/Application Support/rbw/config.json".source =
          jsonFormat.generate "rbw-config.json" cfg.settings;
      })
    ]
  );
}
