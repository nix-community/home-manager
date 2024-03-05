{ config, lib, pkgs, ... }:

with lib;

let

  inherit (config.home) stateVersion;

  cfg = config.home;

  languageSubModule = types.submodule {
    options = {
      base = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use unless overridden by a more specific option.
        '';
      };

      ctype = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          Character classification category.
        '';
      };

      numeric = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for numerical values.
        '';
      };

      time = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for formatting times.
        '';
      };

      collate = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for collation (alphabetical ordering).
        '';
      };

      monetary = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for formatting currencies and money amounts.
        '';
      };

      messages = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for messages, application UI languages, etc.
        '';
      };

      paper = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for paper sizes.
        '';
      };

      name = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for personal names.
        '';
      };

      address = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for addresses.
        '';
      };

      telephone = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for telephone numbers.
        '';
      };

      measurement = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for measurement values.
        '';
      };

    };
  };

  keyboardSubModule = types.submodule {
    options = {
      layout = mkOption {
        type = with types; nullOr str;
        default =
          if versionAtLeast config.home.stateVersion "19.09"
          then null
          else "us";
        defaultText = literalExpression "null";
        description = ''
          Keyboard layout. If `null`, then the system
          configuration will be used.

          This defaults to `null` for state
          version ≥ 19.09 and `"us"` otherwise.
        '';
      };

      model = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "presario";
        description = ''
          Keyboard model.
        '';
      };

      options = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["grp:caps_toggle" "grp_led:scroll"];
        description = ''
          X keyboard options; layout switching goes here.
        '';
      };

      variant = mkOption {
        type = with types; nullOr str;
        default =
          if versionAtLeast config.home.stateVersion "19.09"
          then null
          else "";
        defaultText = literalExpression "null";
        example = "colemak";
        description = ''
          X keyboard variant. If `null`, then the
          system configuration will be used.

          This defaults to `null` for state
          version ≥ 19.09 and `""` otherwise.
        '';
      };
    };
  };

in

{
  meta.maintainers = [ maintainers.rycee ];

  imports = [
    (mkRemovedOptionModule [ "home" "sessionVariableSetter" ] ''
      Session variables are now always set through the shell. This is
      done automatically if the shell configuration is managed by Home
      Manager. If not, then you must source the

        ${cfg.profileDirectory}/etc/profile.d/hm-session-vars.sh

      file yourself.
    '')
  ];

  options = {
    home.username = mkOption {
      type = types.str;
      defaultText = literalExpression ''
        "$USER"   for state version < 20.09,
        undefined for state version ≥ 20.09
      '';
      example = "jane.doe";
      description = "The user's username.";
    };

    home.homeDirectory = mkOption {
      type = types.path;
      defaultText = literalExpression ''
        "$HOME"   for state version < 20.09,
        undefined for state version ≥ 20.09
      '';
      apply = toString;
      example = "/home/jane.doe";
      description = "The user's home directory. Must be an absolute path.";
    };

    home.profileDirectory = mkOption {
      type = types.path;
      defaultText = literalExpression ''
        "''${home.homeDirectory}/.nix-profile"  or
        "/etc/profiles/per-user/''${home.username}"
      '';
      readOnly = true;
      description = ''
        The profile directory where Home Manager generations are installed.
      '';
    };

    home.language = mkOption {
      type = languageSubModule;
      default = {};
      description = "Language configuration.";
    };

    home.keyboard = mkOption {
      type = types.nullOr keyboardSubModule;
      default = if versionAtLeast stateVersion "21.11" then null else { };
      defaultText = literalExpression ''
        "{ }"  for state version < 21.11,
        "null" for state version ≥ 21.11
      '';
      description = ''
        Keyboard configuration. Set to `null` to
        disable Home Manager keyboard management.
      '';
    };

    home.shellAliases = mkOption {
      type = with types; attrsOf str;
      default = { };
      example = literalExpression ''
        {
          g = "git";
          "..." = "cd ../..";
        }
      '';
      description = ''
        An attribute set that maps aliases (the top level attribute names
        in this option) to command strings or directly to build outputs.

        This option should only be used to manage simple aliases that are
        compatible across all shells. If you need to use a shell specific
        feature then make sure to use a shell specific option, for example
        [](#opt-programs.bash.shellAliases) for Bash.
      '';
    };

    home.sessionVariables = mkOption {
      default = {};
      type = with types; lazyAttrsOf (oneOf [ str path int float ]);
      example = { EDITOR = "emacs"; GS_OPTIONS = "-sPAPERSIZE=a4"; };
      description = ''
        Environment variables to always set at login.

        The values may refer to other environment variables using
        POSIX.2 style variable references. For example, a variable
        {var}`parameter` may be referenced as
        `$parameter` or `''${parameter}`. A
        default value `foo` may be given as per
        `''${parameter:-foo}` and, similarly, an alternate
        value `bar` can be given as per
        `''${parameter:+bar}`.

        Note, these variables may be set in any order so no session
        variable may have a runtime dependency on another session
        variable. In particular code like
        ```nix
        home.sessionVariables = {
          FOO = "Hello";
          BAR = "$FOO World!";
        };
        ```
        may not work as expected. If you need to reference another
        session variable, then do so inside Nix instead. The above
        example then becomes
        ```nix
        home.sessionVariables = {
          FOO = "Hello";
          BAR = "''${config.home.sessionVariables.FOO} World!";
        };
        ```
      '';
    };

    home.sessionVariablesPackage = mkOption {
      type = types.package;
      internal = true;
      description = ''
        The package containing the
        {file}`hm-session-vars.sh` file.
      '';
    };

    home.sessionPath = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [
        "$HOME/.local/bin"
        "\${xdg.configHome}/emacs/bin"
        ".git/safe/../../bin"
      ];
      description = ''
        Extra directories to add to {env}`PATH`.

        These directories are added to the {env}`PATH` variable in a
        double-quoted context, so expressions like `$HOME` are
        expanded by the shell. However, since expressions like `~` or
        `*` are escaped, they will end up in the {env}`PATH`
        verbatim.
      '';
    };

    home.sessionVariablesExtra = mkOption {
      type = types.lines;
      default = "";
      internal = true;
      description = ''
        Extra configuration to add to the
        {file}`hm-session-vars.sh` file.
      '';
    };

    home.packages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "The set of packages to appear in the user environment.";
    };

    home.extraOutputsToInstall = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "doc" "info" "devdoc" ];
      description = ''
        List of additional package outputs of the packages
        {var}`home.packages` that should be installed into
        the user environment.
      '';
    };

    home.path = mkOption {
      internal = true;
      description = "The derivation installing the user packages.";
    };

    home.emptyActivationPath = mkOption {
      internal = true;
      type = types.bool;
      default = versionAtLeast stateVersion "22.11";
      defaultText = literalExpression ''
        false   for state version < 22.11,
        true    for state version ≥ 22.11
      '';
      description = ''
        Whether the activation script should start with an empty
        {env}`PATH` variable. When `false` then the
        user's {env}`PATH` will be accessible in the script. It is
        recommended to keep this at `true` to avoid
        uncontrolled use of tools found in PATH.
      '';
    };

    home.activation = mkOption {
      type = hm.types.dagOf types.str;
      default = {};
      example = literalExpression ''
        {
          myActivationAction = lib.hm.dag.entryAfter ["writeBoundary"] '''
            run ln -s $VERBOSE_ARG \
                ''${builtins.toPath ./link-me-directly} $HOME
          ''';
        }
      '';
      description = ''
        The activation scripts blocks to run when activating a Home
        Manager generation. Any entry here should be idempotent,
        meaning running twice or more times produces the same result
        as running it once.

        If the script block produces any observable side effect, such
        as writing or deleting files, then it
        *must* be placed after the special
        `writeBoundary` script block. Prior to the
        write boundary one can place script blocks that verifies, but
        does not modify, the state of the system and exits if an
        unexpected state is found. For example, the
        `checkLinkTargets` script block checks for
        collisions between non-managed files and files defined in
        [](#opt-home.file).

        A script block should respect the {var}`DRY_RUN` variable. If it is set
        then the actions taken by the script should be logged to standard out
        and not actually performed. A convenient shell function {command}`run`
        is provided for activation script blocks. It is used as follows:

        {command}`run {command}`
        : Runs the given command on live run, otherwise prints the command to
        standard output.

        {command}`run --silence {command}`
        : Runs the given command on live run and sends its standard and error
        output to {file}`/dev/null`, otherwise prints the command to standard
        output.

        A script block should also respect the {var}`VERBOSE` variable, and if
        set print information on standard out that may be useful for debugging
        any issue that may arise. The variable {var}`VERBOSE_ARG` is set to
        {option}`--verbose` if verbose output is enabled. You can also use the
        provided shell function {command}`verboseEcho`, which acts as
        {command}`echo` when verbose output is enabled.
      '';
    };

    home.activationPackage = mkOption {
      internal = true;
      type = types.package;
      description = "The package containing the complete activation script.";
    };

    home.activationGenerateGcRoot = mkOption {
      internal = true;
      type = types.bool;
      default = true;
      description = ''
        Whether the activation script should create a GC root to avoid being
        garbage collected. Typically you want this but if you know for certain
        that the Home Manager generation is referenced from some other GC root,
        then it may be appropriate to not create our own root.
      '';
    };

    home.extraActivationPath = mkOption {
      internal = true;
      type = types.listOf types.package;
      default = [ ];
      description = ''
        Extra packages to add to {env}`PATH` within the activation
        script.
      '';
    };

    home.extraBuilderCommands = mkOption {
      type = types.lines;
      default = "";
      internal = true;
      description = ''
        Extra commands to run in the Home Manager generation builder.
      '';
    };

    home.extraProfileCommands = mkOption {
      type = types.lines;
      default = "";
      internal = true;
      description = ''
        Extra commands to run in the Home Manager profile builder.
      '';
    };

    home.enableNixpkgsReleaseCheck = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Determines whether to check for release version mismatch between Home
        Manager and Nixpkgs. Using mismatched versions is likely to cause errors
        and unexpected behavior. It is therefore highly recommended to use a
        release of Home Manager that corresponds with your chosen release of
        Nixpkgs.

        When this option is enabled and a mismatch is detected then a warning
        will be printed when the user configuration is being built.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = config.home.username != "";
        message = "Username could not be determined";
      }
      {
        assertion = config.home.homeDirectory != "";
        message = "Home directory could not be determined";
      }
    ];

    warnings =
      let
        hmRelease = config.home.version.release;
        nixpkgsRelease = lib.trivial.release;
        releaseMismatch =
          config.home.enableNixpkgsReleaseCheck
          && hmRelease != nixpkgsRelease;
      in
        optional releaseMismatch ''
          You are using

            Home Manager version ${hmRelease} and
            Nixpkgs version ${nixpkgsRelease}.

          Using mismatched versions is likely to cause errors and unexpected
          behavior. It is therefore highly recommended to use a release of Home
          Manager that corresponds with your chosen release of Nixpkgs.

          If you insist then you can disable this warning by adding

            home.enableNixpkgsReleaseCheck = false;

          to your configuration.
        '';

    home.username =
      mkIf (versionOlder config.home.stateVersion "20.09")
        (mkDefault (builtins.getEnv "USER"));
    home.homeDirectory =
      mkIf (versionOlder config.home.stateVersion "20.09")
        (mkDefault (builtins.getEnv "HOME"));

    home.profileDirectory =
      if config.submoduleSupport.enable
        && config.submoduleSupport.externalPackageInstall
      then "/etc/profiles/per-user/${cfg.username}"
      else if config.nix.enable && (config.nix.settings.use-xdg-base-directories or false)
      then "${config.xdg.stateHome}/nix/profile"
      else cfg.homeDirectory + "/.nix-profile";

    programs.bash.shellAliases = cfg.shellAliases;
    programs.zsh.shellAliases = cfg.shellAliases;
    programs.fish.shellAliases = cfg.shellAliases;

    home.sessionVariables =
      let
        maybeSet = n: v: optionalAttrs (v != null) { ${n} = v; };
      in
        (maybeSet "LANG" cfg.language.base)
        //
        (maybeSet "LC_CTYPE" cfg.language.ctype)
        //
        (maybeSet "LC_NUMERIC" cfg.language.numeric)
        //
        (maybeSet "LC_TIME" cfg.language.time)
        //
        (maybeSet "LC_COLLATE" cfg.language.collate)
        //
        (maybeSet "LC_MONETARY" cfg.language.monetary)
        //
        (maybeSet "LC_MESSAGES" cfg.language.messages)
        //
        (maybeSet "LC_PAPER" cfg.language.paper)
        //
        (maybeSet "LC_NAME" cfg.language.name)
        //
        (maybeSet "LC_ADDRESS" cfg.language.address)
        //
        (maybeSet "LC_TELEPHONE" cfg.language.telephone)
        //
        (maybeSet "LC_MEASUREMENT" cfg.language.measurement);

    # Provide a file holding all session variables.
    home.sessionVariablesPackage = pkgs.writeTextFile {
      name = "hm-session-vars.sh";
      destination = "/etc/profile.d/hm-session-vars.sh";
      text = ''
        # Only source this once.
        if [ -n "$__HM_SESS_VARS_SOURCED" ]; then return; fi
        export __HM_SESS_VARS_SOURCED=1

        ${config.lib.shell.exportAll cfg.sessionVariables}
      '' + lib.optionalString (cfg.sessionPath != [ ]) ''
        export PATH="$PATH''${PATH:+:}${concatStringsSep ":" cfg.sessionPath}"
      '' + cfg.sessionVariablesExtra;
    };

    home.packages = [ config.home.sessionVariablesPackage ];

    # The entry acting as a boundary between the activation script's "check" and
    # the "write" phases. This is where we commit to attempting to actually
    # activate the configuration.
    #
    # Note, if we are run by a version 0 driver then we update the profile here.
    home.activation.writeBoundary = hm.dag.entryAnywhere ''
      if (( $hmDriverVersion < 1 )); then
        if [[ ! -v oldGenPath || "$oldGenPath" != "$newGenPath" ]] ; then
          _i "Creating new profile generation"
          run nix-env $VERBOSE_ARG --profile "$genProfilePath" --set "$newGenPath"
        else
          _i "No change so reusing latest profile generation"
        fi
      fi
    '';

    # Install packages to the user environment.
    #
    # Note, sometimes our target may not allow modification of the Nix
    # store and then we cannot rely on `nix-env -i`. This is the case,
    # for example, if we are running as a NixOS module and building a
    # virtual machine. Then we must instead rely on an external
    # mechanism for installing packages, which in NixOS is provided by
    # the `users.users.<name?>.packages` option. The activation
    # command is still needed since some modules need to run their
    # activation commands after the packages are guaranteed to be
    # installed.
    #
    # In case the user has moved from a user-install of Home Manager
    # to a submodule managed one we attempt to uninstall the
    # `home-manager-path` package if it is installed.
    home.activation.installPackages = hm.dag.entryAfter ["writeBoundary"] (
      if config.submoduleSupport.externalPackageInstall
      then
        ''
          nixProfileRemove home-manager-path
        ''
      else
        ''
          function nixReplaceProfile() {
            local oldNix="$(command -v nix)"

            nixProfileRemove 'home-manager-path'

            run $oldNix profile install $1
          }

          if [[ -e ${cfg.profileDirectory}/manifest.json ]] ; then
            INSTALL_CMD="nix profile install"
            INSTALL_CMD_ACTUAL="nixReplaceProfile"
            LIST_CMD="nix profile list"
            REMOVE_CMD_SYNTAX='nix profile remove {number | store path}'
          else
            INSTALL_CMD="nix-env -i"
            INSTALL_CMD_ACTUAL="run nix-env -i"
            LIST_CMD="nix-env -q"
            REMOVE_CMD_SYNTAX='nix-env -e {package name}'
          fi

          if ! $INSTALL_CMD_ACTUAL ${cfg.path} ; then
            echo
            _iError $'Oops, Nix failed to install your new Home Manager profile!\n\nPerhaps there is a conflict with a package that was installed using\n"%s"? Try running\n\n    %s\n\nand if there is a conflicting package you can remove it with\n\n    %s\n\nThen try activating your Home Manager configuration again.' "$INSTALL_CMD" "$LIST_CMD" "$REMOVE_CMD_SYNTAX"
            exit 1
          fi
          unset -f nixReplaceProfile
          unset INSTALL_CMD INSTALL_CMD_ACTUAL LIST_CMD REMOVE_CMD_SYNTAX
        ''
    );

    # Text containing Bash commands that will initialize the Home Manager Bash
    # library. Most importantly, this will prepare for using translated strings
    # in the `hm-modules` text domain.
    lib.bash.initHomeManagerLib =
      let
        domainDir = pkgs.runCommand "hm-modules-messages" {
          nativeBuildInputs = [ pkgs.buildPackages.gettext ];
        } ''
          for path in ${./po}/*.po; do
            lang="''${path##*/}"
            lang="''${lang%%.*}"
            mkdir -p "$out/$lang/LC_MESSAGES"
            msgfmt -o "$out/$lang/LC_MESSAGES/hm-modules.mo" "$path"
          done
        '';
      in
        ''
          export TEXTDOMAIN=hm-modules
          export TEXTDOMAINDIR=${domainDir}
          source ${../lib/bash/home-manager.sh}
        '';

    home.activationPackage =
      let
        mkCmd = res: ''
            _iNote "Activating %s" "${res.name}"
            ${res.data}
          '';
        sortedCommands = hm.dag.topoSort cfg.activation;
        activationCmds =
          if sortedCommands ? result then
            concatStringsSep "\n" (map mkCmd sortedCommands.result)
          else
            abort ("Dependency cycle in activation script: "
              + builtins.toJSON sortedCommands);

        # Programs that always should be available on the activation
        # script's PATH.
        activationBinPaths = lib.makeBinPath (
          with pkgs; [
            bash
            coreutils
            diffutils           # For `cmp` and `diff`.
            findutils
            gettext
            gnugrep
            gnused
            jq
            ncurses             # For `tput`.
          ]
          ++ config.home.extraActivationPath
        )
        + (
          # Add path of the Nix binaries, if a Nix package is configured, then
          # use that one, otherwise grab the path of the nix-env tool.
          if config.nix.enable && config.nix.package != null then
            ":${config.nix.package}/bin"
          else
            ":$(${pkgs.coreutils}/bin/dirname $(${pkgs.coreutils}/bin/readlink -m $(type -p nix-env)))"
        )
        + optionalString (!cfg.emptyActivationPath) "\${PATH:+:}$PATH";

        activationScript = pkgs.writeShellScript "activation-script" ''
          set -eu
          set -o pipefail

          cd $HOME

          export PATH="${activationBinPaths}"
          ${config.lib.bash.initHomeManagerLib}

          # The driver version indicates the behavior expected by the caller of
          # this script.
          #
          # - 0 : legacy behavior
          # - 1 : the script will not attempt to update the Home Manager Nix profile.
          hmDriverVersion=0

          while (( $# > 0 )); do
            opt="$1"
            shift

            case $opt in
              --driver-version)
                if (( $# == 0 )); then
                  errorEcho "$0: no driver version specified" >&2
                  exit 1
                elif (( 0 <= $1 && $1 <= 1 )); then
                  hmDriverVersion=$1
                else
                  errorEcho "$0: unexpected driver version $1" >&2
                  exit 1
                fi
                shift
                ;;
              *)
                _iError "%s: unknown option '%s'" "$0" "$opt" >&2
                exit 1
                ;;
            esac
          done
          unset opt

          ${builtins.readFile ./lib-bash/activation-init.sh}

          if [[ ! -v SKIP_SANITY_CHECKS ]]; then
            checkUsername ${escapeShellArg config.home.username}
            checkHomeDirectory ${escapeShellArg config.home.homeDirectory}
          fi

          ${optionalString config.home.activationGenerateGcRoot ''
            # Create a temporary GC root to prevent collection during activation.
            trap 'run rm -f $VERBOSE_ARG "$newGenGcPath"' EXIT
            run --silence nix-store --realise "$newGenPath" --add-root "$newGenGcPath"
          ''}

          ${activationCmds}

          ${optionalString (config.home.activationGenerateGcRoot && !config.uninstall) ''
            # Create the "current generation" GC root.
            run --silence nix-store --realise "$newGenPath" --add-root "$currentGenGcPath"

            if [[ -e "$legacyGenGcPath" ]]; then
              run rm $VERBOSE_ARG "$legacyGenGcPath"
            fi
          ''}
        '';
      in
        pkgs.runCommand
          "home-manager-generation"
          {
            preferLocalBuild = true;
          }
          ''
            mkdir -p $out

            echo "${config.home.version.full}" > $out/hm-version

            # The gen-version indicates the format of the generation package
            # itself. It allows us to make backwards incompatible changes in the
            # package output and have surrounding tooling adapt.
            echo 1 > $out/gen-version

            cp ${activationScript} $out/activate

            mkdir $out/bin
            ln -s $out/activate $out/bin/home-manager-generation

            substituteInPlace $out/activate \
              --subst-var-by GENERATION_DIR $out

            ln -s ${config.home-files} $out/home-files
            ln -s ${cfg.path} $out/home-path

            ${cfg.extraBuilderCommands}
          '';

    home.path = pkgs.buildEnv {
      name = "home-manager-path";

      paths = cfg.packages;
      inherit (cfg) extraOutputsToInstall;

      postBuild = cfg.extraProfileCommands;

      meta = {
        description = "Environment of packages installed through home-manager";
      };
    };
  };
}
