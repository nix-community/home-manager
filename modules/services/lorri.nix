{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.lorri;

in
{
  meta.maintainers = [
    lib.maintainers.gerschtli
    lib.maintainers.nyarly
  ];

  options.services.lorri = {
    enable = lib.mkEnableOption "lorri build daemon";

    enableNotifications = lib.mkEnableOption "lorri build notifications";

    package = lib.mkPackageOption pkgs "lorri" { };

    nixPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nix;
      defaultText = lib.literalExpression "pkgs.nix";
      example = lib.literalExpression "pkgs.nixVersions.unstable";
      description = "Which nix package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.lorri" pkgs lib.platforms.linux)
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
          ];
          CacheDirectory = [ "lorri" ];
          Restart = "on-failure";
          Environment =
            let
              path =
                with pkgs;
                lib.makeSearchPath "bin" [
                  cfg.nixPackage
                  gitMinimal
                  gnutar
                  gzip
                ];
            in
            [ "PATH=${path}" ];
        };
      };

      sockets.lorri = {
        Unit = {
          Description = "Socket for lorri build daemon";
        };

        Socket = {
          ListenStream = "%t/lorri/daemon.socket";
          RuntimeDirectory = "lorri";
        };

        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };

      services.lorri-notify = lib.mkIf cfg.enableNotifications {
        Unit = {
          Description = "lorri build notifications";
          After = "lorri.service";
          Requires = "lorri.service";
        };

        Service = {
          ExecStart =
            let
              jqFile = ''
                (
                  (.Started?   | values | ["Build starting", .nix_file, "emblem-synchronizing"]),
                  (.Completed? | values | ["Build complete", .nix_file, "checkmark"]),
                  (.Failure?   | values | ["Build failed", .nix_file, "dialog-error"])
                )
                | @tsv
              '';

              notifyScript = pkgs.writeShellScript "lorri-notify" ''
                lorri internal stream-events --kind live \
                  | jq --unbuffered -r '${jqFile}' \
                  | while IFS=$'\t' read -r status nixFile icon; do
                      notify-send --app-name "Lorri" --hint=int:transient:1 \
                        --icon "$icon" "$status" "$nixFile"
                    done
              '';
            in
            toString notifyScript;
          Restart = "on-failure";
          Environment =
            let
              path = lib.makeSearchPath "bin" (
                with pkgs;
                [
                  bash
                  jq
                  libnotify
                  cfg.package
                ]
              );
            in
            "PATH=${path}";
        };

        Install = {
          WantedBy = [ "lorri.service" ];
        };
      };
    };
  };
}
