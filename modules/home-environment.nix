{ config, lib, pkgs, ... }:

with lib;
with import ./lib/dag.nix;

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
  options = {
    home.file = mkOption {
      description = "Attribute set of files to link into the user home.";
      default = {};
      type = types.loaOf (types.submodule (
        { name, config, ... }: {
          options = {
            target = mkOption {
              type = types.str;
              description = ''
                Path to target file relative to <envar>HOME</envar>.
              '';
            };

            text = mkOption {
              default = null;
              type = types.nullOr types.lines;
              description = "Text of the file.";
            };

            source = mkOption {
              type = types.path;
              description = ''
                Path of the source file. The file name must not start
                with a period since Nix will not allow such names in
                the Nix store.
                </para><para>
                This may refer to a directory.
              '';
            };

            mode = mkOption {
              type = types.str;
              default = "444";
              description = "The permissions to apply to the file.";
            };
          };

          config = {
            target = mkDefault name;
            source = mkIf (config.text != null) (
              let name' = "user-etc-" + baseNameOf name;
              in mkDefault (pkgs.writeText name' config.text)
            );
          };
        })
      );
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
      type = types.enum [ "pam" "bash" ];
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
  };

  config = {
    assertions = [
      (let
        badFiles =
          filter (f: hasPrefix "." (baseNameOf f))
          (map (v: toString v.source)
          (attrValues cfg.file));
        badFilesStr = toString badFiles;
      in
        {
          assertion = badFiles == [];
          message = "Source file names must not start with '.': ${badFilesStr}";
        })
    ];

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

    home.activation.linkGeneration = dagEntryAfter ["writeBoundary"] (
      let
        link = pkgs.writeText "link" ''
          newGenFiles="$1"
          shift
          for sourcePath in "$@" ; do
            relativePath="''${sourcePath#$newGenFiles/}"
            targetPath="$HOME/$relativePath"
            $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$(dirname "$targetPath")"
            $DRY_RUN_CMD ln -nsf $VERBOSE_ARG "$sourcePath" "$targetPath"
          done
        '';

        cleanup = pkgs.writeText "cleanup" ''
          newGenFiles="$1"
          oldGenFiles="$2"
          shift 2
          for sourcePath in "$@" ; do
            relativePath="''${sourcePath#$oldGenFiles/}"
            targetPath="$HOME/$relativePath"
            if [[ -e "$newGenFiles/$relativePath" ]] ; then
              $VERBOSE_ECHO "Checking $targetPath  exists"
            else
              echo "Checking $targetPath  gone (deleting)"
              $DRY_RUN_CMD rm $VERBOSE_ARG "$targetPath"
              $DRY_RUN_CMD rmdir --ignore-fail-on-non-empty \
                  $VERBOSE_ARG -p "$(dirname "$targetPath")"
            fi
          done
        '';
      in
        ''
          function linkNewGen() {
            local newGenFiles
            newGenFiles="$(readlink -e "$newGenPath/home-files")"
            find "$newGenFiles" -type f -print0 -or -type l -print0 \
              | xargs -0 bash ${link} "$newGenFiles"
          }

          function cleanOldGen() {
            if [[ ! -v oldGenPath ]] ; then
              return
            fi

            echo "Cleaning up orphan links from $HOME"

            local newGenFiles oldGenFiles
            newGenFiles="$(readlink -e "$newGenPath/home-files")"
            oldGenFiles="$(readlink -e "$oldGenPath/home-files")"
            find "$oldGenFiles" -type f -print0 -or -type l -print0 \
              | xargs -0 bash ${cleanup} "$newGenFiles" "$oldGenFiles"
          }

          if [[ ! -v oldGenPath || "$oldGenPath" != "$newGenPath" ]] ; then
            echo "Creating profile generation $newGenNum"
            $DRY_RUN_CMD ln -Tsf $VERBOSE_ARG "$newGenPath" "$newGenProfilePath"
            $DRY_RUN_CMD ln -Tsf $VERBOSE_ARG "$newGenProfilePath" "$genProfilePath"
            $DRY_RUN_CMD ln -Tsf $VERBOSE_ARG "$newGenPath" "$newGenGcPath"
          else
            echo "No change so reusing latest profile generation $oldGenNum"
          fi

          linkNewGen
          cleanOldGen
        ''
    );

    home.activation.installPackages = dagEntryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD nix-env -i ${cfg.path}
    '';

    home.activationPackage =
      let
        mkCmd = res: ''
            echo Activating ${res.name}
            ${res.data}
          '';
        sortedCommands = dagTopoSort cfg.activation;
        activationCmds =
          if sortedCommands ? result then
            concatStringsSep "\n" (map mkCmd sortedCommands.result)
          else
            abort ("Dependency cycle in activation script: "
              + builtins.toJSON sortedCommands);

        sf = pkgs.writeText "activation-script" ''
          #!${pkgs.stdenv.shell}

          set -eu
          set -o pipefail

          ${builtins.readFile ./activation-init.sh}

          ${activationCmds}
        '';

        home-files = pkgs.stdenv.mkDerivation {
          name = "home-manager-files";

          phases = [ "installPhase" ];

          installPhase =
            "mkdir -p $out\n" +
            concatStringsSep "\n" (
              mapAttrsToList (n: v:
                ''
                  if [ -d "${v.source}" ]; then
                    mkdir -pv "$(dirname "$out/${v.target}")"
                    ln -sv "${v.source}" "$out/${v.target}"
                  else
                    install -D -m${v.mode} "${v.source}" "$out/${v.target}"
                  fi
                ''
              ) cfg.file
            );
        };
      in
        pkgs.stdenv.mkDerivation {
          name = "home-manager-generation";

          phases = [ "installPhase" ];

          installPhase = ''
            install -D -m755 ${sf} $out/activate

            substituteInPlace $out/activate \
              --subst-var-by GENERATION_DIR $out

            ln -s ${home-files} $out/home-files
          '';
        };

    home.path = pkgs.buildEnv {
      name = "home-manager-path";

      paths = cfg.packages;

      meta = {
        description = "Environment of packages installed through home-manager";
      };
    };
  };
}
