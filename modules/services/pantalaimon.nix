{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.pantalaimon;

  iniFmt = pkgs.formats.ini { };
in
{
  meta.maintainers = [ lib.maintainers.jojosch ];

  options = {
    services.pantalaimon = {
      enable = lib.mkEnableOption "Pantalaimon, an E2EE aware proxy daemon for matrix clients";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.pantalaimon;
        defaultText = lib.literalExpression "pkgs.pantalaimon";
        description = "Package providing the {command}`pantalaimon` executable to use.";
      };

      settings = lib.mkOption {
        type = iniFmt.type;
        default = { };
        defaultText = lib.literalExpression "{ }";
        example = lib.literalExpression ''
          {
            Default = {
              LogLevel = "Debug";
              SSL = true;
            };
            local-matrix = {
              Homeserver = "https://matrix.org";
              ListenAddress = "127.0.0.1";
              ListenPort = 8008;
            };
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/pantalaimon/pantalaimon.conf`.

          See <https://github.com/matrix-org/pantalaimon/blob/master/docs/manpantalaimon.5.md> or
          {manpage}`pantalaimon(5)`
          for options.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.pantalaimon" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services = {
      pantalaimon = {
        Unit = {
          Description = "Pantalaimon - E2EE aware proxy daemon for matrix clients";
          After = [ "network-online.target" ];
        };

        Service = {
          ExecStart = "${cfg.package}/bin/pantalaimon -c ${iniFmt.generate "pantalaimon.conf" cfg.settings}";
          Restart = "on-failure";
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
  };
}
