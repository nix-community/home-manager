{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.services.etesync-dav;

  toEnvironmentCfg =
    vars: (lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "${k}=${lib.escapeShellArg v}") vars));

in
{
  meta.maintainers = [ lib.maintainers.valodim ];

  options.services.etesync-dav = {
    enable = lib.mkEnableOption "etesync-dav";

    package = mkOption {
      type = types.package;
      default = pkgs.etesync-dav;
      defaultText = "pkgs.etesync-dav";
      description = "The etesync-dav derivation to use.";
    };

    serverUrl = mkOption {
      type = types.str;
      default = "https://api.etebase.com/partner/etesync/";
      description = "The URL to the etesync server.";
    };

    settings = mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.str
          types.int
        ]
      );
      default = { };
      example = lib.literalExpression ''
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.etesync-dav" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.etesync-dav = {
      Unit = {
        Description = "etesync-dav";
      };

      Service = {
        ExecStart = "${cfg.package}/bin/etesync-dav";
        Environment = toEnvironmentCfg ({ ETESYNC_URL = cfg.serverUrl; } // cfg.settings);
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
