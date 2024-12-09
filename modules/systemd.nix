{ config, lib, pkgs, ... }:

let

  cfg = config.systemd.user;

  inherit (lib)
    any attrValues getAttr hm isBool literalExpression mkIf mkMerge
    mkEnableOption mkOption types;

  settingsFormat = pkgs.formats.ini { listsAsDuplicateKeys = true; };

  # From <nixpkgs/nixos/modules/system/boot/systemd-lib.nix>
  mkPathSafeName =
    lib.replaceStrings [ "@" ":" "\\" "[" "]" ] [ "-" "-" "-" "" "" ];

  removeIfEmpty = attrs: names:
    lib.filterAttrs (name: value: !(builtins.elem name names) || value != "")
    attrs;

  toSystemdIni = lib.generators.toINI {
    listsAsDuplicateKeys = true;
    mkKeyValue = key: value:
      let
        value' = if isBool value then
          (if value then "true" else "false")
        else
          toString value;
      in "${key}=${value'}";
  };

  buildService = style: name: serviceCfg:
    let
      filename = "${name}.${style}";
      pathSafeName = mkPathSafeName filename;

      # Needed because systemd derives unit names from the ultimate
      # link target.
      source = pkgs.writeTextFile {
        name = pathSafeName;
        text = toSystemdIni serviceCfg;
        destination = "/${filename}";
      } + "/${filename}";

      install = variant: target: {
        name = "systemd/user/${target}.${variant}/${filename}";
        value = { inherit source; };
      };
    in lib.singleton {
      name = "systemd/user/${filename}";
      value = { inherit source; };
    } ++ map (install "wants") (serviceCfg.Install.WantedBy or [ ])
    ++ map (install "requires") (serviceCfg.Install.RequiredBy or [ ]);

  buildServices = style: serviceCfgs:
    lib.concatLists (lib.mapAttrsToList (buildService style) serviceCfgs);

  servicesStartTimeoutMs = builtins.toString cfg.servicesStartTimeoutMs;

  unitType = unitKind:
    with types;
    let primitive = oneOf [ bool int str path ];
    in attrsOf (attrsOf (attrsOf (either primitive (listOf primitive)))) // {
      description = "systemd ${unitKind} unit configuration";
    };

  unitDescription = type: ''
    Definition of systemd per-user ${type} units. Attributes are
    merged recursively.

    Note that the attributes follow the capitalization and naming used
    by systemd. More details can be found in
    {manpage}`systemd.${type}(5)`.
  '';

  unitExample = type:
    literalExpression ''
      {
        ${lib.toLower type}-name = {
          Unit = {
            Description = "Example description";
            Documentation = [ "man:example(1)" "man:example(5)" ];
          };

          ${type} = {
            …
          };
        };
      };
    '';

  sessionVariables = mkIf (cfg.sessionVariables != { }) {
    "environment.d/10-home-manager.conf".text = lib.concatStringsSep "\n"
      (lib.mapAttrsToList (n: v: "${n}=${toString v}") cfg.sessionVariables)
      + "\n";
  };

  settings = mkIf (any (v: v != { }) (attrValues cfg.settings)) {
    "systemd/user.conf".source =
      settingsFormat.generate "user.conf" cfg.settings;
  };

  configHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;

in {
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    systemd.user = {
      enable = mkEnableOption "the user systemd service manager" // {
        default = pkgs.stdenv.isLinux;
        defaultText = literalExpression "pkgs.stdenv.isLinux";
      };

      systemctlPath = mkOption {
        default = "${pkgs.systemd}/bin/systemctl";
        defaultText = literalExpression ''"''${pkgs.systemd}/bin/systemctl"'';
        type = types.str;
        description = ''
          Absolute path to the {command}`systemctl` tool. This
          option may need to be set if running Home Manager on a
          non-NixOS distribution.
        '';
      };

      services = mkOption {
        default = { };
        type = unitType "service";
        description = (unitDescription "service");
        example = unitExample "Service";
      };

      slices = mkOption {
        default = { };
        type = unitType "slice";
        description = (unitDescription "slice");
        example = unitExample "Slice";
      };

      sockets = mkOption {
        default = { };
        type = unitType "socket";
        description = (unitDescription "socket");
        example = unitExample "Socket";
      };

      targets = mkOption {
        default = { };
        type = unitType "target";
        description = (unitDescription "target");
        example = unitExample "Target";
      };

      timers = mkOption {
        default = { };
        type = unitType "timer";
        description = (unitDescription "timer");
        example = unitExample "Timer";
      };

      paths = mkOption {
        default = { };
        type = unitType "path";
        description = (unitDescription "path");
        example = unitExample "Path";
      };

      mounts = mkOption {
        default = { };
        type = unitType "mount";
        description = (unitDescription "mount");
        example = unitExample "Mount";
      };

      automounts = mkOption {
        default = { };
        type = unitType "automount";
        description = (unitDescription "automount");
        example = unitExample "Automount";
      };

      startServices = mkOption {
        default = "suggest";
        type = with types;
          either bool (enum [ "suggest" "legacy" "sd-switch" ]);
        apply = p: if isBool p then if p then "sd-switch" else "suggest" else p;
        description = ''
          Whether new or changed services that are wanted by active targets
          should be started. Additionally, stop obsolete services from the
          previous generation.

          The alternatives are

          `suggest` (or `false`)
          : Use a very simple shell script to print suggested
            {command}`systemctl` commands to run. You will have to
            manually run those commands after the switch.

          `legacy`
          : Use a Ruby script to, in a more robust fashion, determine the
            necessary changes and automatically run the
            {command}`systemctl` commands. Note, this alternative will soon
            be removed.

          `sd-switch` (or `true`)
          : Use sd-switch, a tool that determines the necessary changes and
            automatically apply them.
        '';
      };

      servicesStartTimeoutMs = mkOption {
        default = 0;
        type = types.ints.unsigned;
        description = ''
          How long to wait for started services to fail until their start is
          considered successful. The value 0 indicates no timeout.
        '';
      };

      sessionVariables = mkOption {
        default = { };
        type = with types; attrsOf (either int str);
        example = { EDITOR = "vim"; };
        description = ''
          Environment variables that will be set for the user session.
          The variable values must be as described in
          {manpage}`environment.d(5)`.
        '';
      };

      settings = mkOption {
        apply = sections:
          sections // {
            # Setting one of these to an empty value would reset any
            # previous settings, so we’ll remove them instead if they
            # are not explicitly set.
            Manager = removeIfEmpty sections.Manager [
              "ManagerEnvironment"
              "DefaultEnvironment"
            ];
          };

        type = types.submodule {
          freeformType = settingsFormat.type;

          options = let
            inherit (lib) concatStringsSep escapeShellArg mapAttrsToList;
            environmentOption = args:
              mkOption {
                type = with types;
                  attrsOf (nullOr (oneOf [ str path package ]));
                default = { };
                example = literalExpression ''
                  {
                    PATH = "%u/bin:%u/.cargo/bin";
                  }
                '';
                apply = value:
                  concatStringsSep " "
                  (mapAttrsToList (n: v: "${n}=${escapeShellArg v}") value);
              } // args;
          in {
            Manager = {
              DefaultEnvironment = environmentOption {
                description = ''
                  Configures environment variables passed to all executed processes.
                '';
              };
              ManagerEnvironment = environmentOption {
                description = ''
                  Sets environment variables just for the manager process itself.
                '';
              };
            };
          };
        };
        default = { };
        example = literalExpression ''
          {
            Manager.DefaultCPUAccounting = true;
          }
        '';
        description = ''
          Extra config options for user session service manager. See {manpage}`systemd-user.conf(5)` for
          available options.
        '';
      };
    };
  };

  # If we run under a Linux system we assume that systemd is
  # available, in particular we assume that systemctl is in PATH.
  # Do not install any user services if username is root.
  config = mkIf (cfg.enable && config.home.username != "root") {
    assertions = [{
      assertion = pkgs.stdenv.isLinux;
      message = "This module is only available on Linux.";
    }];

    warnings = lib.optional (cfg.startServices == "legacy") ''
      Having 'systemd.user.startServices = "legacy"' is deprecated and will soon be removed.

      Please change to 'systemd.user.startServices = true' to use the new systemd unit switcher (sd-switch).
    '';

    xdg.configFile = mkMerge [
      (lib.listToAttrs ((buildServices "service" cfg.services)
        ++ (buildServices "slice" cfg.slices)
        ++ (buildServices "socket" cfg.sockets)
        ++ (buildServices "target" cfg.targets)
        ++ (buildServices "timer" cfg.timers)
        ++ (buildServices "path" cfg.paths)
        ++ (buildServices "mount" cfg.mounts)
        ++ (buildServices "automount" cfg.automounts)))

      sessionVariables

      settings
    ];

    # Run systemd service reload if user is logged in. If we're
    # running this from the NixOS module then XDG_RUNTIME_DIR is not
    # set and systemd commands will fail. We'll therefore have to
    # set it ourselves in that case.
    home.activation.reloadSystemd = hm.dag.entryAfter [ "linkGeneration" ] (let
      cmd = {
        suggest = ''
          bash ${./systemd-activate.sh} "''${oldGenPath=}" "$newGenPath"
        '';
        legacy = ''
          ${pkgs.ruby}/bin/ruby ${./systemd-activate.rb} \
            "''${oldGenPath=}" "$newGenPath" "${servicesStartTimeoutMs}"
        '';
        sd-switch = let
          timeoutArg = if cfg.servicesStartTimeoutMs != 0 then
            "--timeout " + servicesStartTimeoutMs
          else
            "";
        in ''
          ${lib.getExe pkgs.sd-switch} \
            ''${DRY_RUN:+--dry-run} $VERBOSE_ARG ${timeoutArg} \
            ''${oldUnitsDir:+--old-units $oldUnitsDir} \
            --new-units "$newUnitsDir"
        '';
      };

      # Make sure that we have an environment where we are likely to
      # successfully talk with systemd.
      ensureSystemd = ''
        env XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
            PATH="${dirOf cfg.systemctlPath}:$PATH" \
      '';

      systemctl = "${ensureSystemd} systemctl";
    in ''
      systemdStatus=$(${systemctl} --user is-system-running 2>&1 || true)

      if [[ $systemdStatus == 'running' || $systemdStatus == 'degraded' ]]; then
        if [[ $systemdStatus == 'degraded' ]]; then
          warnEcho "The user systemd session is degraded:"
          ${systemctl} --user --no-pager --state=failed
          warnEcho "Attempting to reload services anyway..."
        fi

        if [[ -v oldGenPath ]]; then
          oldUnitsDir="$oldGenPath/home-files${configHome}/systemd/user"
          if [[ ! -e $oldUnitsDir ]]; then
            oldUnitsDir=
          fi
        fi

        newUnitsDir="$newGenPath/home-files${configHome}/systemd/user"
        if [[ ! -e $newUnitsDir ]]; then
          newUnitsDir=${pkgs.emptyDirectory}
        fi

        ${ensureSystemd} ${getAttr cfg.startServices cmd}

        unset newUnitsDir oldUnitsDir
      else
        echo "User systemd daemon not running. Skipping reload."
      fi

      unset systemdStatus
    '');
  };
}
