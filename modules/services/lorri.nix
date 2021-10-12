{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.lorri;

in {
  meta.maintainers = [ maintainers.gerschtli ];

  options.services.lorri = {
    enable = mkEnableOption "lorri build daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.lorri;
      defaultText = literalExpression "pkgs.lorri";
      description = "Which lorri package to install.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.lorri" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user = {
      services.lorri = {
        Unit = {
          Description = "lorri build daemon";
          Requires = "lorri.socket";
          After = "lorri.socket";
          RefuseManualStart = true;
        };

        Service = {
          ExecStart = "${cfg.package}/bin/lorri daemon";
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          Restart = "on-failure";
          Environment = let
            path = with pkgs;
              makeSearchPath "bin" [ nix gitMinimal gnutar gzip ];
          in [ "PATH=${path}" ];
        };
      };

      sockets.lorri = {
        Unit = { Description = "Socket for lorri build daemon"; };

        Socket = {
          ListenStream = "%t/lorri/daemon.socket";
          RuntimeDirectory = "lorri";
        };

        Install = { WantedBy = [ "sockets.target" ]; };
      };
    };
  };
}
