{ config, lib, pkgs, ... }:

let

  cfg = config.systemd.user;

  inherit (lib) getAttr hm isBool literalExpression mkIf mkMerge mkOption types;

  # From <nixpkgs/nixos/modules/system/boot/systemd-lib.nix>
  mkPathSafeName =
    lib.replaceChars [ "@" ":" "\\" "[" "]" ] [ "-" "-" "-" "" "" ];

  enabled = cfg.services != { } # \
    || cfg.slices != { } # \
    || cfg.sockets != { } # \
    || cfg.targets != { } # \
    || cfg.timers != { } # \
    || cfg.paths != { } # \
    || cfg.mounts != { } # \
    || cfg.automounts != { } # \
    || cfg.sessionVariables != { };

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
        destination = lib.escapeShellArg "/${filename}";
      } + "/${filename}";

      wantedBy = target: {
        name = "systemd/user/${target}.wants/${filename}";
        value = { inherit source; };
      };
    in lib.singleton {
      name = "systemd/user/${filename}";
      value = { inherit source; };
    } ++ map wantedBy (serviceCfg.Install.WantedBy or [ ]);

  buildServices = style: serviceCfgs:
    lib.concatLists (lib.mapAttrsToList (buildService style) serviceCfgs);

  servicesStartTimeoutMs = builtins.toString cfg.servicesStartTimeoutMs;

  unitType = unitKind:
    with types;
    let primitive = either bool (either int str);
    in attrsOf (attrsOf (attrsOf (either primitive (listOf primitive)))) // {
      description = "systemd ${unitKind} unit configuration";
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

in {
  meta.maintainers = [ lib.maintainers.rycee ];

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
        default = { };
        type = unitType "service";
        description = unitDescription "service";
        example = unitExample "Service";
      };

      slices = mkOption {
        default = { };
        type = unitType "slices";
        description = unitDescription "slices";
        example = unitExample "Slices";
      };

      sockets = mkOption {
        default = { };
        type = unitType "socket";
        description = unitDescription "socket";
        example = unitExample "Socket";
      };

      targets = mkOption {
        default = { };
        type = unitType "target";
        description = unitDescription "target";
        example = unitExample "Target";
      };

      timers = mkOption {
        default = { };
        type = unitType "timer";
        description = unitDescription "timer";
        example = unitExample "Timer";
      };

      paths = mkOption {
        default = { };
        type = unitType "path";
        description = unitDescription "path";
        example = unitExample "Path";
      };

      mounts = mkOption {
        default = { };
        type = unitType "mount";
        description = unitDescription "mount";
        example = unitExample "Mount";
      };

      automounts = mkOption {
        default = { };
        type = unitType "automount";
        description = unitDescription "automount";
        example = unitExample "Automount";
      };

      startServices = mkOption {
        default = "suggest";
        type = with types;
          either bool (enum [ "suggest" "legacy" "sd-switch" ]);
        apply = p: if isBool p then if p then "legacy" else "suggest" else p;
        description = ''
          Whether new or changed services that are wanted by active targets
          should be started. Additionally, stop obsolete services from the
          previous generation.
          </para><para>
          The alternatives are
          <variablelist>
          <varlistentry>
            <term><literal>suggest</literal> (or <literal>false</literal>)</term>
            <listitem><para>
              Use a very simple shell script to print suggested
              <command>systemctl</command> commands to run. You will have to
              manually run those commands after the switch.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>legacy</literal> (or <literal>true</literal>)</term>
            <listitem><para>
              Use a Ruby script to, in a more robust fashion, determine the
              necessary changes and automatically run the
              <command>systemctl</command> commands.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>sd-switch</literal></term>
            <listitem><para>
              Use sd-switch, a third party application, to perform the service
              updates. This tool offers more features while having a small
              closure size. Note, it requires a fully functional user D-Bus
              session. Once tested and deemed sufficiently robust, this will
              become the default.
            </para></listitem>
          </varlistentry>
          </variablelist>
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
          <citerefentry>
            <refentrytitle>environment.d</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry>.
        '';
      };
    };
  };

  config = mkMerge [
    {
      assertions = [{
        assertion = enabled -> pkgs.stdenv.isLinux;
        message = let
          names = lib.concatStringsSep ", " (lib.attrNames ( # \
            cfg.services # \
            // cfg.slices # \
            // cfg.sockets # \
            // cfg.targets # \
            // cfg.timers # \
            // cfg.paths # \
            // cfg.mounts # \
            // cfg.sessionVariables));
        in "Must use Linux for modules that require systemd: " + names;
      }];
    }

    # If we run under a Linux system we assume that systemd is
    # available, in particular we assume that systemctl is in PATH.
    # Do not install any user services if username is root.
    (mkIf (pkgs.stdenv.isLinux && config.home.username != "root") {
      xdg.configFile = mkMerge [
        (lib.listToAttrs ((buildServices "service" cfg.services)
          ++ (buildServices "slices" cfg.slices)
          ++ (buildServices "socket" cfg.sockets)
          ++ (buildServices "target" cfg.targets)
          ++ (buildServices "timer" cfg.timers)
          ++ (buildServices "path" cfg.paths)
          ++ (buildServices "mount" cfg.mounts)
          ++ (buildServices "automount" cfg.automounts)))

        sessionVariables
      ];

      # Run systemd service reload if user is logged in. If we're
      # running this from the NixOS module then XDG_RUNTIME_DIR is not
      # set and systemd commands will fail. We'll therefore have to
      # set it ourselves in that case.
      home.activation.reloadSystemd = hm.dag.entryAfter [ "linkGeneration" ]
        (let
          cmd = {
            suggest = ''
              PATH=${dirOf cfg.systemctlPath}:$PATH \
              bash ${./systemd-activate.sh} "''${oldGenPath=}" "$newGenPath"
            '';
            legacy = ''
              PATH=${dirOf cfg.systemctlPath}:$PATH \
              ${pkgs.ruby}/bin/ruby ${./systemd-activate.rb} \
                "''${oldGenPath=}" "$newGenPath" "${servicesStartTimeoutMs}"
            '';
            sd-switch = let
              timeoutArg = if cfg.servicesStartTimeoutMs != 0 then
                "--timeout " + servicesStartTimeoutMs
              else
                "";
            in ''
              ${pkgs.sd-switch}/bin/sd-switch \
                ''${DRY_RUN:+--dry-run} $VERBOSE_ARG ${timeoutArg} \
                ''${oldGenPath:+--old-units $oldGenPath/home-files/.config/systemd/user} \
                --new-units $newGenPath/home-files/.config/systemd/user
            '';
          };

          ensureRuntimeDir =
            "XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}";

          systemctl = "${ensureRuntimeDir} ${cfg.systemctlPath}";
        in ''
          systemdStatus=$(${systemctl} --user is-system-running 2>&1 || true)

          if [[ $systemdStatus == 'running' || $systemdStatus == 'degraded' ]]; then
            if [[ $systemdStatus == 'degraded' ]]; then
              warnEcho "The user systemd session is degraded:"
              ${systemctl} --user --no-pager --state=failed
              warnEcho "Attempting to reload services anyway..."
            fi

            ${ensureRuntimeDir} \
              ${getAttr cfg.startServices cmd}
          else
            echo "User systemd daemon not running. Skipping reload."
          fi

          unset systemdStatus
        '');
    })
  ];
}
