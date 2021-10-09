{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.pantalaimon;

  iniFmt = pkgs.formats.ini { };
in {
  meta.maintainers = [ maintainers.jojosch ];

  options = {
    services.pantalaimon = {
      enable = mkEnableOption
        "Pantalaimon, an E2EE aware proxy daemon for matrix clients";

      package = mkOption {
        type = types.package;
        default = pkgs.pantalaimon;
        defaultText = literalExpression "pkgs.pantalaimon";
        description =
          "Package providing the <command>pantalaimon</command> executable to use.";
      };

      settings = mkOption {
        type = iniFmt.type;
        default = { };
        defaultText = literalExpression "{ }";
        example = literalExpression ''
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
          <filename>$XDG_CONFIG_HOME/pantalaimon/pantalaimon.conf</filename>.
          </para><para>
          See <link xlink:href="https://github.com/matrix-org/pantalaimon/blob/master/docs/manpantalaimon.5.md" /> or
          <citerefentry>
            <refentrytitle>pantalaimon</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry>
          for options.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.pantalaimon" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services = {
      pantalaimon = {
        Unit = {
          Description =
            "Pantalaimon - E2EE aware proxy daemon for matrix clients";
          After = [ "network-online.target" ];
        };

        Service = {
          ExecStart = "${cfg.package}/bin/pantalaimon -c ${
              iniFmt.generate "pantalaimon.conf" cfg.settings
            }";
          Restart = "on-failure";
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
  };
}
