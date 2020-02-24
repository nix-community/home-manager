{ config, lib, pkgs, ... }:

with lib;

let

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

      address = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for addresses.
        '';
      };

      monetary = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for formatting currencies and money amounts.
        '';
      };

      paper = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for paper sizes.
        '';
      };

      time = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The language to use for formatting times.
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
        defaultText = literalExample "null";
        description = ''
          Keyboard layout. If <literal>null</literal>, then the system
          configuration will be used.
          </para><para>
          This defaults to <literal>null</literal> for state
          version ≥ 19.09 and <literal>"us"</literal> otherwise.
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
        defaultText = literalExample "null";
        example = "colemak";
        description = ''
          X keyboard variant. If <literal>null</literal>, then the
          system configuration will be used.
          </para><para>
          This defaults to <literal>null</literal> for state
          version ≥ 19.09 and <literal>""</literal> otherwise.
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

        ~/.nix-profile/etc/profile.d/hm-session-vars.sh

      file yourself.
    '')
  ];

  options = {
    home.username = mkOption {
      type = types.str;
      defaultText = "$USER";
      description = "The user's username.";
    };

    home.homeDirectory = mkOption {
      type = types.path;
      defaultText = "$HOME";
      description = "The user's home directory.";
    };

    home.profileDirectory = mkOption {
      type = types.path;
      defaultText = "~/.nix-profile";
      internal = true;
      readOnly = true;
      description = ''
        The profile directory where Home Manager generations are
        installed.
      '';
    };

    home.language = mkOption {
      type = languageSubModule;
      default = {};
      description = "Language configuration.";
    };

    home.keyboard = mkOption {
      type = types.nullOr keyboardSubModule;
      default = {};
      description = ''
        Keyboard configuration. Set to <literal>null</literal> to
        disable Home Manager keyboard management.
      '';
    };

    home.sessionVariables = mkOption {
      default = {};
      type = types.attrs;
      example = { EDITOR = "emacs"; GS_OPTIONS = "-sPAPERSIZE=a4"; };
      description = ''
        Environment variables to always set at login.
        </para><para>
        The values may refer to other environment variables using
        POSIX.2 style variable references. For example, a variable
        <varname>parameter</varname> may be referenced as
        <code>$parameter</code> or <code>''${parameter}</code>. A
        default value <literal>foo</literal> may be given as per
        <code>''${parameter:-foo}</code> and, similarly, an alternate
        value <literal>bar</literal> can be given as per
        <code>''${parameter:+bar}</code>.
        </para><para>
        Note, these variables may be set in any order so no session
        variable may have a runtime dependency on another session
        variable. In particular code like
        <programlisting language="nix">
        home.sessionVariables = {
          FOO = "Hello";
          BAR = "$FOO World!";
        };
        </programlisting>
        may not work as expected. If you need to reference another
        session variable, then do so inside Nix instead. The above
        example then becomes
        <programlisting language="nix">
        home.sessionVariables = {
          FOO = "Hello";
          BAR = "''${config.home.sessionVariables.FOO} World!";
        };
        </programlisting>
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
        <varname>home.packages</varname> that should be installed into
        the user environment.
      '';
    };

    home.path = mkOption {
      internal = true;
      description = "The derivation installing the user packages.";
    };

    home.emptyActivationPath = mkOption {
      internal = true;
      default = false;
      type = types.bool;
      description = ''
        Whether the activation script should start with an empty
        <envvar>PATH</envvar> variable. When <literal>false</literal>
        then the user's <envvar>PATH</envvar> will be used.
      '';
    };

    home.activation = mkOption {
      type = hm.types.dagOf types.str;
      default = {};
      example = literalExample ''
        {
          myActivationAction = lib.hm.dag.entryAfter ["writeBoundary"] '''
            $DRY_RUN_CMD ln -s $VERBOSE_ARG \
                ''${builtins.toPath ./link-me-directly} $HOME
          ''';
        }
      '';
      description = ''
        The activation scripts blocks to run when activating a Home
        Manager generation. Any entry here should be idempotent,
        meaning running twice or more times produces the same result
        as running it once.

        </para><para>

        If the script block produces any observable side effect, such
        as writing or deleting files, then it
        <emphasis>must</emphasis> be placed after the special
        <literal>writeBoundary</literal> script block. Prior to the
        write boundary one can place script blocks that verifies, but
        does not modify, the state of the system and exits if an
        unexpected state is found. For example, the
        <literal>checkLinkTargets</literal> script block checks for
        collisions between non-managed files and files defined in
        <varname><link linkend="opt-home.file">home.file</link></varname>.

        </para><para>

        A script block should respect the <varname>DRY_RUN</varname>
        variable, if it is set then the actions taken by the script
        should be logged to standard out and not actually performed.
        The variable <varname>DRY_RUN_CMD</varname> is set to
        <command>echo</command> if dry run is enabled.

        </para><para>

        A script block should also respect the
        <varname>VERBOSE</varname> variable, and if set print
        information on standard out that may be useful for debugging
        any issue that may arise. The variable
        <varname>VERBOSE_ARG</varname> is set to
        <option>--verbose</option> if verbose output is enabled.
      '';
    };

    home.activationPackage = mkOption {
      internal = true;
      type = types.package;
      description = "The package containing the complete activation script.";
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

    home.username = mkDefault (builtins.getEnv "USER");
    home.homeDirectory = mkDefault (builtins.getEnv "HOME");

    home.profileDirectory =
      if config.submoduleSupport.enable
        && config.submoduleSupport.externalPackageInstall
      then config.home.path
      else cfg.homeDirectory + "/.nix-profile";

    home.sessionVariables =
      let
        maybeSet = n: v: optionalAttrs (v != null) { ${n} = v; };
      in
        (maybeSet "LANG" cfg.language.base)
        //
        (maybeSet "LC_ADDRESS" cfg.language.address)
        //
        (maybeSet "LC_MONETARY" cfg.language.monetary)
        //
        (maybeSet "LC_PAPER" cfg.language.paper)
        //
        (maybeSet "LC_TIME" cfg.language.time);

    home.packages = [
      # Provide a file holding all session variables.
      (
        pkgs.writeTextFile {
          name = "hm-session-vars.sh";
          destination = "/etc/profile.d/hm-session-vars.sh";
          text = ''
            # Only source this once.
            if [ -n "$__HM_SESS_VARS_SOURCED" ]; then return; fi
            export __HM_SESS_VARS_SOURCED=1

            ${config.lib.shell.exportAll cfg.sessionVariables}
          '';
        }
      )
    ];

    # A dummy entry acting as a boundary between the activation
    # script's "check" and the "write" phases.
    home.activation.writeBoundary = hm.dag.entryAnywhere "";

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
          if nix-env -q | grep '^home-manager-path$'; then
            $DRY_RUN_CMD nix-env -e home-manager-path
          fi
        ''
      else
        ''
          $DRY_RUN_CMD nix-env -i ${cfg.path}
        ''
    );

    home.activationPackage =
      let
        mkCmd = res: ''
            noteEcho Activating ${res.name}
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
        activationBinPaths = lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
          pkgs.diffutils        # For `cmp` and `diff`.
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.ncurses          # For `tput`.
        ]
        + optionalString (!cfg.emptyActivationPath) "\${PATH:+:}$PATH";

        activationScript = pkgs.writeScript "activation-script" ''
          #!${pkgs.runtimeShell}

          set -eu
          set -o pipefail

          cd $HOME

          export PATH="${activationBinPaths}"

          . ${./lib-bash/color-echo.sh}

          ${builtins.readFile ./lib-bash/activation-init.sh}

          # Some activation blocks may need to maintain some state, which
          # should be kept in this directory. We consider creation of this
          # directory exempt from the write boundary.
          $DRY_RUN_CMD mkdir $VERBOSE_ARG -p "${config.xdg.dataHome}/home-manager"

          ${activationCmds}
        '';
      in
        pkgs.runCommand
          "home-manager-generation"
          {
            preferLocalBuild = true;
            allowSubstitutes = false;
          }
          ''
            mkdir -p $out

            cp ${activationScript} $out/activate

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
