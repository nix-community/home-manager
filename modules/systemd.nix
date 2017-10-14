{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.systemd.user;

  dag = config.lib.dag;

  enabled = cfg.services != {}
      || cfg.sockets != {}
      || cfg.targets != {}
      || cfg.timers != {};

  toSystemdIni = generators.toINI {
    mkKeyValue = key: value:
      let
        value' =
          if isBool value then (if value then "true" else "false")
          else toString value;
      in
        "${key}=${value'}";
  };

  buildService = style: name: serviceCfg:
    let
      filename = "${name}.${style}";

      # Needed because systemd derives unit names from the ultimate
      # link target.
      source = pkgs.writeTextDir filename (toSystemdIni serviceCfg)
        + "/" + filename;

      wantedBy = target:
        {
          name = "systemd/user/${target}.wants/${filename}";
          value = { inherit source; };
        };
    in
      singleton {
        name = "systemd/user/${filename}";
        value = { inherit source; };
      }
      ++
      map wantedBy (serviceCfg.Install.WantedBy or []);

  buildServices = style: serviceCfgs:
    concatLists (mapAttrsToList (buildService style) serviceCfgs);

  servicesStartTimeoutMs = builtins.toString cfg.servicesStartTimeoutMs;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    systemd.user = {
      systemctlPath = mkOption {
        default = "${pkgs.systemd}/bin/systemctl";
        defaultText = "\${pkgs.systemd}/bin/systemctl";
        type = types.str;
        description = ''
          Absolute path to the <command>systemctl</command> tool. This
          option may need to be set if running Home Manager on a
          non-NixOS distribution.
        '';
      };

      services = mkOption {
        default = {};
        type = types.attrs;
        description = "Definition of systemd per-user service units.";
      };

      sockets = mkOption {
        default = {};
        type = types.attrs;
        description = "Definition of systemd per-user sockets";
      };

      targets = mkOption {
        default = {};
        type = types.attrs;
        description = "Definition of systemd per-user targets";
      };

      timers = mkOption {
        default = {};
        type = types.attrs;
        description = "Definition of systemd per-user timers";
      };

      startServices = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Start all services that are wanted by active targets.
          Additionally, stop obsolete services from the previous
          generation.
        '';
      };

      servicesStartTimeoutMs = mkOption {
        default = 0;
        type = types.int;
        description = ''
          How long to wait for started services to fail until their
          start is considered successful.
        '';
      };
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = enabled -> pkgs.stdenv.isLinux;
          message =
            let
              names = concatStringsSep ", " (
                  attrNames (
                      cfg.services // cfg.sockets // cfg.targets // cfg.timers
                  )
              );
            in
              "Must use Linux for modules that require systemd: " + names;
        }
      ];
    }

    # If we run under a Linux system we assume that systemd is
    # available, in particular we assume that systemctl is in PATH.
    (mkIf pkgs.stdenv.isLinux {
      xdg.configFile =
        listToAttrs (
          (buildServices "service" cfg.services)
          ++
          (buildServices "socket" cfg.sockets)
          ++
          (buildServices "target" cfg.targets)
          ++
          (buildServices "timer" cfg.timers)
        );

      # Run systemd service reload if user is logged in. If we're
      # running this from the NixOS module then XDG_RUNTIME_DIR is not
      # set and systemd commands will fail. We'll therefore have to
      # set it ourselves in that case.
      home.activation.reloadSystemD = dag.entryAfter ["linkGeneration"] (
        let
          autoReloadCmd = ''
            ${pkgs.ruby}/bin/ruby ${./systemd-activate.rb} \
              "''${oldGenPath=}" "$newGenPath" "${servicesStartTimeoutMs}"
          '';

          legacyReloadCmd = ''
            bash ${./systemd-activate.sh} "''${oldGenPath=}" "$newGenPath"
          '';
        in
          ''
            if who | grep -q '^${config.home.username} '; then
              XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)} \
              PATH=${dirOf cfg.systemctlPath}:$PATH \
                ${if cfg.startServices then autoReloadCmd else legacyReloadCmd}
            else
              echo "User ${config.home.username} not logged in. Skipping."
            fi
          ''
      );
    })
  ];
}
