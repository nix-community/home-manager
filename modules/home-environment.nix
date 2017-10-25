{ config, lib, pkgs, ... }:

with lib;
with import ./lib/dag.nix { inherit lib; };

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
        type = types.str;
        default = "us";
        description = ''
          Keyboard layout.
        '';
      };

      model = mkOption {
        type = types.str;
        default = "pc104";
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
        type = types.str;
        default = "";
        example = "colemak";
        description = ''
          X keyboard variant.
        '';
      };
    };
  };

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    home.username = mkOption {
      type = types.str;
      defaultText = "$USER";
      readOnly = true;
      description = "The user's username";
    };

    home.homeDirectory = mkOption {
      type = types.path;
      defaultText = "$HOME";
      readOnly = true;
      description = "The user's home directory";
    };

    home.language = mkOption {
      type = languageSubModule;
      default = {};
      description = "Language configuration.";
    };

    home.keyboard = mkOption {
      type = keyboardSubModule;
      default = {};
      description = "Keyboard configuration.";
    };

    home.sessionVariables = mkOption {
      default = {};
      type = types.attrs;
      example = { EDITOR = "emacs"; GS_OPTIONS = "-sPAPERSIZE=a4"; };
      description = ''
        Environment variables to always set at login.
      '';
    };

    home.sessionVariableSetter = mkOption {
      default = "bash";
      type = types.enum [ "pam" "bash" "zsh" ];
      example = "pam";
      description = ''
        Identifies the module that should set the session variables.
        </para><para>
        If "bash" is set then <varname>config.bash.enable</varname>
        must also be enabled.
        </para><para>
        If "pam" is set then PAM must be used to set the system
        environment. Also mind that typical environment variables
        might not be set by the time PAM starts up.
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

    home.activation = mkOption {
      internal = true;
      default = {};
      type = types.attrs;
      description = ''
        Activation scripts for the home environment.
        </para><para>
        Any script should respect the <varname>DRY_RUN</varname>
        variable, if it is set then no actual action should be taken.
        The variable <varname>DRY_RUN_CMD</varname> is set to
        <code>echo</code> if dry run is enabled. Thus, many cases you
        can use the idiom <code>$DRY_RUN_CMD rm -rf /</code>.
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

    home.sessionVariables =
      let
        maybeSet = name: value:
          listToAttrs (optional (value != null) { inherit name value; });
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

    # A dummy entry acting as a boundary between the activation
    # script's "check" and the "write" phases.
    home.activation.writeBoundary = dagEntryAnywhere "";

    home.activation.installPackages = dagEntryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD nix-env -i ${cfg.path}
    '';

    home.activationPackage =
      let
        mkCmd = res: ''
            noteEcho Activating ${res.name}
            ${res.data}
          '';
        sortedCommands = dagTopoSort cfg.activation;
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
          pkgs.nix
        ];

        sf = pkgs.writeText "activation-script" ''
          #!${pkgs.stdenv.shell}

          set -eu
          set -o pipefail

          cd $HOME

          export PATH="${activationBinPaths}:$PATH"

          . ${./lib-bash/color-echo.sh}

          ${builtins.readFile ./lib-bash/activation-init.sh}

          ${activationCmds}
        '';
      in
        pkgs.stdenv.mkDerivation {
          name = "home-manager-generation";

          phases = [ "installPhase" ];

          installPhase = ''
            install -D -m755 ${sf} $out/activate

            substituteInPlace $out/activate \
              --subst-var-by GENERATION_DIR $out

            ln -s ${config.home-files} $out/home-files
            ln -s ${cfg.path} $out/home-path

            ${cfg.extraBuilderCommands}
          '';
        };

    home.path = pkgs.buildEnv {
      name = "home-manager-path";

      paths = cfg.packages;
      inherit (cfg) extraOutputsToInstall;

      meta = {
        description = "Environment of packages installed through home-manager";
      };
    };
  };
}
