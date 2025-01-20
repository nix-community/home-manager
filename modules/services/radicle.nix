{ config, lib, pkgs, options, ... }:
let
  inherit (lib)
    generators getBin getExe getExe' mapAttrsToList mkDefault mkEnableOption
    mkIf mkOption mkPackageOption;

  inherit (lib.types) attrsOf nullOr oneOf package path str;

  cfg = config.services.radicle;
  opt = options.services.radicle;

  radicleHome = config.home.homeDirectory + "/.radicle";

  gitPath = [ "PATH=${getBin config.programs.git.package}/bin" ];
  env = attrs:
    (mapAttrsToList (generators.mkKeyValueDefault { } "=") attrs) ++ gitPath;
in {
  meta.maintainers = with lib.maintainers; [ lorenzleutgeb ];

  options = {
    services.radicle = {
      node = {
        enable = mkEnableOption "Radicle Node";
        package = mkPackageOption pkgs "radicle-node" { };
        args = mkOption {
          type = str;
          default = "";
          example = "--listen 0.0.0.0:8776";
        };
        environment = mkOption {
          type = attrsOf (nullOr (oneOf [ str path package ]));
          default = { };
        };
      };
      httpd = {
        enable = mkEnableOption "Radicle HTTP Daemon";
        package = mkPackageOption pkgs "radicle-httpd" { };
        args = mkOption {
          type = str;
          default = "--listen 127.0.0.1:8080";
        };
        environment = mkOption {
          type = attrsOf (nullOr (oneOf [ str path package ]));
          default = cfg.node.enable;
        };
      };
    };
  };

  config = mkIf (cfg.node.enable || cfg.httpd.enable) {
    assertions = [{
      assertion = cfg.httpd.enable -> cfg.node.enable;
      message = "`${opt.httpd.enable}` requires `${opt.node.enable}`, "
        + "since `radicle-httpd` depends on `radicle-node`";
    }];
    systemd.user = {
      services = {
        "radicle-keys" = {
          Unit = {
            Description = "Radicle Keys";
            Documentation = [
              "man:rad(1)"
              "https://radicle.xyz/guides/user#come-into-being-from-the-elliptic-aether"
            ];
            After = [ "default.target" ];
            Requires = [ "default.target" ];
          };
          Service = {
            Type = "oneshot";
            Slice = "background.slice";
            ExecStart = getExe (pkgs.writeShellApplication {
              name = "radicle-keys.sh";
              runtimeInputs = [ pkgs.coreutils ];
              text = let
                keyFile = name: "${radicleHome}/keys/${name}";
                keyPair = name: [ (keyFile name) (keyFile (name + ".pub")) ];
                radicleKeyPair = keyPair "radicle";
              in ''
                echo testing
                FILES=(${builtins.concatStringsSep " " radicleKeyPair})
                if stat --terse "''${FILES[@]}"
                then
                  # Happy path, we're done!
                  exit 0
                fi

                cat <<EOM
                At least one of the following files does not exist, but all should!

                $(printf '  %s\n' "''${FILES[@]}")

                In order for Radicle to work, please initialize by executing

                  rad auth

                or provisioning pre-existing keys manually, e.g.

                  ln -s ~/.ssh/id_ed25519     ${keyFile "radicle"}
                  ln -s ~/.ssh/id_ed25519.pub ${keyFile "radicle.pub"}
                EOM
                exit 1
              '';
            });
          };
        };
        "radicle-node" = mkIf cfg.node.enable {
          Unit = {
            Description = "Radicle Node";
            After = [ "radicle-keys.service" ];
            Requires = [ "radicle-keys.service" ];
            Documentation =
              [ "https://radicle.xyz/guides" "man:radicle-node(1)" ];
          };
          Service = {
            Slice = "session.slice";
            ExecStart =
              "${getExe' cfg.node.package "radicle-node"} ${cfg.node.args}";
            Environment = env cfg.node.environment;
            KillMode = "process";
            Restart = "always";
            RestartSec = "2";
            RestartSteps = "100";
            RestartDelayMaxSec = "1min";
          };
        };
        "radicle-httpd" = mkIf cfg.httpd.enable {
          Unit = {
            Description = "Radicle HTTP Daemon";
            After = [ "radicle-node.service" ];
            Requires = [ "radicle-node.service" ];
            Documentation =
              [ "https://radicle.xyz/guides" "man:radicle-httpd(1)" ];
          };
          Service = {
            Slice = "session.slice";
            ExecStart =
              "${getExe' cfg.httpd.package "radicle-httpd"} ${cfg.httpd.args}";
            Environment = env cfg.httpd.environment;
            KillMode = "process";
            Restart = "always";
            RestartSec = "4";
            RestartSteps = "100";
            RestartDelayMaxSec = "2min";
          };
        };
      };
      sockets."radicle-node" = mkIf cfg.node.enable {
        Unit = {
          Description = "Radicle Node Control Socket";
          Documentation = [ "man:radicle-node(1)" ];
        };
        Socket.ListenStream = "${radicleHome}/node/control.sock";
        Install.WantedBy = [ "sockets.target" ];
      };
    };
    programs.radicle.enable = mkDefault true;
  };
}
