{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    generators
    getBin
    getExe'
    last
    mapAttrsToList
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    mkMerge
    mkPackageOption
    splitString
    ;

  inherit (lib.types)
    attrsOf
    nullOr
    oneOf
    package
    path
    str
    ;

  cfg = config.services.radicle;

  radicleHome = config.home.homeDirectory + "/.radicle";

  gitPath = [ "PATH=${getBin pkgs.gitMinimal}/bin" ];
  env = attrs: (mapAttrsToList (generators.mkKeyValueDefault { } "=") attrs) ++ gitPath;
in
{
  meta.maintainers = with lib.maintainers; [
    lorenzleutgeb
    matthiasbeyer
  ];

  options = {
    services.radicle = {
      node = {
        enable = mkEnableOption "Radicle Node";
        package = mkPackageOption pkgs "radicle-node" { };
        args = mkOption {
          type = str;
          description = "Additional command line arguments to pass when executing `radicle-node`.";
          default = "";
          example = "--force";
        };
        environment = mkOption {
          type = attrsOf (
            nullOr (oneOf [
              str
              path
              package
            ])
          );
          description = "Environment to set when executing `radicle-node`.";
          default = { };
          example = {
            "RUST_BACKTRACE" = "full";
          };
        };
        lazy = {
          enable = mkEnableOption "a proxy service to lazily start and stop Radicle Node on demand";
          exitIdleTime = mkOption {
            type = str;
            description = "The idle time after which no interaction with Radicle Node via the `rad` CLI should be stopped, in a format that {manpage}`systemd-socket-proxyd(8)` understands for its `--exit-idle-time` argument.";
            default = "30min";
            example = "1h";
          };
        };
      };
    };
  };

  config = mkIf cfg.node.enable {
    systemd.user = {
      services = {
        "radicle-node" =
          let
            keyFile = name: "${radicleHome}/keys/${name}";
            keyPair = name: [
              (keyFile name)
              (keyFile (name + ".pub"))
            ];
            radicleKeyPair = keyPair "radicle";
          in
          {
            Unit = {
              Description = "Radicle Node";
              Documentation = [
                "https://radicle.xyz/guides"
                "man:radicle-node(1)"
              ];
              StopWhenUnneeded = cfg.node.lazy.enable;
              ConditionPathExists = radicleKeyPair;
            };
            Service = mkMerge [
              {
                Slice = "session.slice";
                ExecStart = "${getExe' cfg.node.package "radicle-node"} ${cfg.node.args}";
                Environment = env cfg.node.environment;
                KillMode = "process";
                Restart = "no";
                RestartSec = "2";
                RestartSteps = "100";
                RestartMaxDelaySec = "1min";
              }
              {
                # Hardening

                BindPaths = [
                  "${radicleHome}/storage"
                  "${radicleHome}/node"
                  "${radicleHome}/cobs"
                ];

                BindReadOnlyPaths = [
                  "${radicleHome}/config.json"
                  "${radicleHome}/keys"
                  "-/etc/resolv.conf"
                  "/run/systemd"
                ];

                RestrictAddressFamilies = [
                  "AF_UNIX"
                  "AF_INET"
                  "AF_INET6"
                ];

                AmbientCapabilities = "";
                CapabilityBoundingSet = "";
                NoNewPrivileges = true;

                DeviceAllow = ""; # ProtectClock= adds DeviceAllow=char-rtc r
                KeyringMode = "private";
                LockPersonality = true;
                MemoryDenyWriteExecute = true;
                PrivateDevices = true;
                PrivateTmp = true;
                PrivateUsers = "self";

                ProcSubset = "pid";
                ProtectClock = true;
                ProtectHome = "tmpfs";
                ProtectHostname = true;
                ProtectKernelLogs = true;
                ProtectProc = "invisible";
                ProtectSystem = "strict";

                RestrictNamespaces = true;
                RestrictRealtime = true;
                RestrictSUIDSGID = true;

                RuntimeDirectoryMode = "0700";

                SocketBindDeny = [ "any" ];
                SocketBindAllow = map (
                  addr: "tcp:${last (splitString ":" addr)}"
                ) config.programs.radicle.settings.node.listen;

                StateDirectoryMode = "0750";
                UMask = "0067";

                SystemCallArchitectures = "native";
                SystemCallFilter = [
                  "@system-service"
                  "~@aio"
                  "~@chown"
                  "~@keyring"
                  "~@memlock"
                  "~@privileged"
                  "~@resources"
                  "~@setuid"
                ];
              }
            ];
            Install.WantedBy = mkIf (!cfg.node.lazy.enable) [ "default.target" ];
          };
        "radicle-node-proxy" = mkIf cfg.node.lazy.enable {
          Unit = {
            Description = "Radicle Node Proxy";
            BindsTo = [
              "radicle-node-proxy.socket"
              "radicle-node.service"
            ];
            After = [
              "radicle-node-proxy.socket"
              "radicle-node.service"
            ];
            Documentation = [ "man:systemd-socket-proxyd(8)" ];
          };
          Service = {
            ExecSearchPath = "${pkgs.systemd}/lib/systemd";
            ExecStart = "systemd-socket-proxyd --exit-idle-time=${cfg.node.lazy.exitIdleTime} %t/radicle-node/proxy.sock";
            PrivateTmp = "yes";
            PrivateNetwork = "yes";
            RuntimeDirectory = "radicle";
            RuntimeDirectoryPreserve = "yes";
          };
        };
      };
      sockets = mkIf cfg.node.lazy.enable {
        "radicle-node-control" = {
          Unit = {
            Description = "Radicle Node Control Socket";
            Documentation = [ "man:radicle-node(1)" ];
          };
          Socket = {
            Service = "radicle-node-proxy.service";
            ListenStream = "%t/radicle-node/control.sock";
            RuntimeDirectory = "radicle-node";
            RuntimeDirectoryPreserve = "yes";
          };
          Install.WantedBy = [ "sockets.target" ];
        };
        "radicle-node-proxy" = {
          Unit = {
            Description = "Radicle Node Proxy Socket";
            Documentation = [ "man:systemd-socket-proxyd(8)" ];
          };
          Socket = {
            Service = "radicle-node.service";
            FileDescriptorName = "control";
            ListenStream = "%t/radicle-node/proxy.sock";
            RuntimeDirectory = "radicle-node";
            RuntimeDirectoryPreserve = "yes";
          };
          Install.WantedBy = [ "sockets.target" ];
        };
      };
    };
    programs.radicle.enable = mkDefault true;
    home.sessionVariables = mkIf cfg.node.lazy.enable {
      RAD_SOCKET = "\${XDG_RUNTIME_DIR:-/run/user/$UID}/radicle-node/control.sock";
    };
  };
}
