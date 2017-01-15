{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.home;

  languageSubModule = types.submodule {
    options = {
      base = mkOption {
        type = types.str;
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
              description = "Path of the source file.";
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
      description = "Environment variables to always set at login.";
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
      description = "Activation scripts for the home environment.";
    };

    home.activationPackage = mkOption {
      internal = true;
      type = types.package;
      description = "The package containing the complete activation script.";
    };
  };

  config = {
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

    home.activation.linkages =
      let
        link = pkgs.writeText "link" ''
          newGenFiles="$1"
          shift
          for sourcePath in "$@" ; do
            relativePath="$(realpath --relative-to "$newGenFiles" "$sourcePath")"
            targetPath="$HOME/$relativePath"
            mkdir -vp "$(dirname "$targetPath")"
            ln -vsf "$sourcePath" "$targetPath"
          done
        '';

        cleanup = pkgs.writeText "cleanup" ''
          newGenFiles="$1"
          oldGenFiles="$2"
          shift 2
          for sourcePath in "$@" ; do
            relativePath="$(realpath --relative-to "$oldGenFiles" "$sourcePath")"
            targetPath="$HOME/$relativePath"
            echo -n "Checking $targetPath"
            if [[ -f "$newGenFiles/$relativePath" ]] ; then
              echo "  exists"
            else
              echo "  gone (deleting)"
              rm -v "$targetPath"
              rmdir --ignore-fail-on-non-empty -v -p "$(dirname "$targetPath")"
            fi
          done
        '';
      in
        ''
          function setupVars() {
            local profilesPath="/nix/var/nix/profiles/per-user/$(whoami)"
            local gcPath="/nix/var/nix/gcroots/per-user/$(whoami)"
            local greatestGenNum=( \
              $(find "$profilesPath" -name 'home-manager-*-link' \
                | sed 's/^.*-\([0-9]*\)-link$/\1/' \
                | sort -rn \
                | head -1) \
            )

            if [[ -n "$greatestGenNum" ]] ; then
              oldGenNum=$greatestGenNum
              newGenNum=$(($oldGenNum + 1))
            else
              newGenNum=1
            fi

            if [[ -e "$gcPath/current-home" ]] ; then
              oldGenPath="$(readlink -e "$gcPath/current-home")"
            fi

            newGenPath="@GENERATION_DIR@";
            newGenProfilePath="$profilesPath/home-manager-$newGenNum-link"
            newGenGcPath="$gcPath/current-home"
          }

          # Set some vars, these can be used later on as well.
          setupVars

          echo oldGenNum=$oldGenNum
          echo newGenNum=$newGenNum
          echo oldGenPath=$oldGenPath
          echo newGenPath=$newGenPath
          echo newGenProfilePath=$newGenProfilePath
          echo newGenGcPath=$newGenGcPath

          function linkNewGen() {
            local newGenFiles
            newGenFiles="$(readlink -e "$newGenPath/home-files")"
            find "$newGenFiles" -type f -print0 \
              | xargs -0 bash ${link} "$newGenFiles"
          }

          function cleanOldGen() {
            if [[ -z "$oldGenPath" ]] ; then
              return
            fi

            echo "Cleaning up orphan links from $HOME"

            local newGenFiles oldGenFiles
            newGenFiles="$(readlink -e "$newGenPath/home-files")"
            oldGenFiles="$(readlink -e "$oldGenPath/home-files")"
            find "$oldGenFiles" -type f -print0 \
              | xargs -0 bash ${cleanup} "$newGenFiles" "$oldGenFiles"
          }

          if [[ "$oldGenPath" != "$newGenPath" ]] ; then
            ln -Tsfv "$newGenPath" "$newGenProfilePath"
            ln -Tsfv "$newGenPath" "$newGenGcPath"
            linkNewGen
            cleanOldGen
          else
            echo "Same home files as previous generation ... doing nothing"
          fi
        '';

    home.activation.installPackages =
      ''
        nix-env -i ${cfg.path}
      '';

    home.activationPackage =
      let
        addHeader = n: v:
          v // {
            text = ''
              echo Activating ${n}
              ${v.text}
            '';
          };
        toDepString = n: v: if isString v then noDepEntry v else v;
        activationWithDeps =
          mapAttrs addHeader (mapAttrs toDepString cfg.activation);
        activationCmds =
          textClosureMap id activationWithDeps (attrNames activationWithDeps);

        sf = pkgs.writeText "activation-script" ''
          #!${pkgs.stdenv.shell}

          ${activationCmds}
        '';

        home-files = pkgs.stdenv.mkDerivation {
          name = "home-manager-files";

          phases = [ "installPhase" ];

          installPhase =
            concatStringsSep "\n" (
              mapAttrsToList (name: value:
                "install -v -D -m${value.mode} ${value.source} $out/${value.target}"
              ) cfg.file
            );
        };
      in
        pkgs.stdenv.mkDerivation {
          name = "home-manager-generation";

          phases = [ "installPhase" ];

          installPhase = ''
            install -v -D -m755 ${sf} $out/activate

            substituteInPlace $out/activate \
              --subst-var-by GENERATION_DIR $out

            ln -vs ${home-files} $out/home-files
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
