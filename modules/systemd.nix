{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.systemd.user;

  dag = config.lib.dag;

  enabled = cfg.services != {}
      || cfg.sockets != {}
      || cfg.targets != {}
      || cfg.timers != {}
      || cfg.paths != {};

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
      pathSafeName = lib.replaceChars ["@" ":" "\\" "[" "]"]
                                      ["-" "-" "-"  ""  "" ]
                                      filename;

      # Needed because systemd derives unit names from the ultimate
      # link target.
      source = pkgs.writeTextFile {
        name = pathSafeName;
        text = toSystemdIni serviceCfg;
        destination = "/${filename}";
      } + "/${filename}";

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

  attrsRecursivelyMerged = types.attrs // {
    merge = loc: foldl' (res: def: recursiveUpdate res def.value) {};
  };

  unitDescription = type: ''
    Definition of systemd per-user ${type} units. Attributes are
    merged recursively.
    </para><para>
    Note that the attributes follow the capitalization and naming used
    by systemd. More details can be found in
    <citerefentry>
      <refentrytitle>systemd.${type}</refentrytitle>
      <manvolnum>5</manvolnum>
    </citerefentry>.
  '';

  unitExample = type: literalExample ''
    {
      Unit = {
        Description = "Example description";
      };

      ${type} = {
        …
      };
    }
  '';

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
        type = attrsRecursivelyMerged;
        description = unitDescription "service";
        example = unitExample "Service";
      };

      sockets = mkOption {
        default = {};
        type = attrsRecursivelyMerged;
        description = unitDescription "socket";
        example = unitExample "Socket";
      };

      targets = mkOption {
        default = {};
        type = attrsRecursivelyMerged;
        description = unitDescription "target";
        example = unitExample "Target";
      };

      timers = mkOption {
        default = {};
        type = attrsRecursivelyMerged;
        description = unitDescription "timer";
        example = unitExample "Timer";
      };

      paths = mkOption {
        default = {};
        type = attrsRecursivelyMerged;
        description = unitDescription "path";
        example = unitExample "Path";
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
                      cfg.services // cfg.sockets // cfg.targets // cfg.timers // cfg.paths
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
          ++
          (buildServices "path" cfg.paths)
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

          ensureRuntimeDir = "XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}";
        in
          ''
            if ${ensureRuntimeDir} ${cfg.systemctlPath} --quiet --user is-system-running 2> /dev/null; then
              ${ensureRuntimeDir} \
              PATH=${dirOf cfg.systemctlPath}:$PATH \
                ${if cfg.startServices then autoReloadCmd else legacyReloadCmd}
            else
              echo "User systemd daemon not running. Skipping reload."
            fi
          ''
      );
    })
  ];
}
