{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.lorri;

in {
  meta.maintainers = [ maintainers.gerschtli maintainers.nyarly ];

  options.services.lorri = {
    enable = mkEnableOption "lorri build daemon";

    enableNotifications = mkEnableOption "lorri build notifications";

    package = mkOption {
      type = types.package;
      default = pkgs.lorri;
      defaultText = literalExpression "pkgs.lorri";
      description = "Which lorri package to install.";
    };

    nixPackage = mkOption {
      type = types.package;
      default = pkgs.nix;
      defaultText = literalExpression "pkgs.nix";
      example = literalExpression "pkgs.nixVersions.unstable";
      description = "Which nix package to use.";
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
          ReadWritePaths = [
            # /run/user/1000 for the socket
            "%t"
            # Needs to update own cache
            "%C/lorri"
            # Needs %C/nix/fetcher-cache-v1.sqlite
            "%C/nix"
            "/nix/var/nix/gcroots/per-user/%u"
          ];
          CacheDirectory = [ "lorri" ];
          Restart = "on-failure";
          Environment = let
            path = with pkgs;
              makeSearchPath "bin" [ cfg.nixPackage gitMinimal gnutar gzip ];
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

      services.lorri-notify = mkIf cfg.enableNotifications {
        Unit = {
          Description = "lorri build notifications";
          After = "lorri.service";
          Requires = "lorri.service";
        };

        Service = {
          ExecStart = let
            jqFile = ''
              (
                (.Started?   | values | "Build starting in \(.nix_file)"),
                (.Completed? | values | "Build complete in \(.nix_file)"),
                (.Failure?   | values | "Build failed in \(.nix_file)")
              )
            '';

            notifyScript = pkgs.writeShellScript "lorri-notify" ''
              lorri internal stream-events --kind live \
                | jq --unbuffered '${jqFile}' \
                | xargs -n 1 notify-send "Lorri Build"
            '';
          in toString notifyScript;
          Restart = "on-failure";
          Environment = let
            path = makeSearchPath "bin"
              (with pkgs; [ bash jq findutils libnotify cfg.package ]);
          in "PATH=${path}";
        };
      };
    };
  };
}
