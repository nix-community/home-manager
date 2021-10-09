{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.etesync-dav;

  toEnvironmentCfg = vars:
    (concatStringsSep " "
      (mapAttrsToList (k: v: "${k}=${escapeShellArg v}") vars));

in {
  meta.maintainers = [ maintainers.valodim ];

  options.services.etesync-dav = {
    enable = mkEnableOption "etesync-dav";

    package = mkOption {
      type = types.package;
      default = pkgs.etesync-dav;
      defaultText = "pkgs.etesync-dav";
      description = "The etesync-dav derivation to use.";
    };

    serverUrl = mkOption {
      type = types.str;
      default = "https://api.etesync.com/";
      description = "The URL to the etesync server.";
    };

    settings = mkOption {
      type = types.attrsOf (types.oneOf [ types.str types.int ]);
      default = { };
      example = literalExpression ''
        {
          ETESYNC_LISTEN_ADDRESS = "localhost";
          ETESYNC_LISTEN_PORT = 37358;
        }
      '';
      description = ''
        Settings for etesync-dav, passed as environment variables.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.etesync-dav" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.etesync-dav = {
      Unit = { Description = "etesync-dav"; };

      Service = {
        ExecStart = "${cfg.package}/bin/etesync-dav";
        Environment =
          toEnvironmentCfg ({ ETESYNC_URL = cfg.serverUrl; } // cfg.settings);
      };

      Install = { WantedBy = [ "default.target" ]; };
    };
  };
}
