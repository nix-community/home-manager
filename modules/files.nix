{ pkgs, config, lib, ... }:

with lib;
with import ./lib/dag.nix { inherit lib; };

let

  cfg = config.home.file;

  homeDirectory = config.home.homeDirectory;

  # Figures out a valid Nix store name for the given path.
  storeFileName = path:
    let
      # All characters that are considered safe. Note "-" is not
      # included to avoid "-" followed by digit being interpreted as a
      # version.
      safeChars =
        [ "+" "." "_" "?" "=" ]
        ++ lowerChars
        ++ upperChars
        ++ stringToCharacters "0123456789";

      empties = l: genList (x: "") (length l);

      unsafeInName = stringToCharacters (
        replaceStrings safeChars (empties safeChars) path
      );

      safeName = replaceStrings unsafeInName (empties unsafeInName) path;
    in
      "home_file_" + safeName;

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
              apply = removePrefix (homeDirectory + "/");
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
              mkDefault (pkgs.writeText (storeFileName name) config.text)
            );
          };
        })
      );
    };

    home-files = mkOption {
      type = types.package;
      internal = true;
      description = "Package to contain all home files";
    };
  };

  config = {
    assertions = [
      (let
        badFiles =
          filter (f: hasPrefix "." (baseNameOf f))
          (map (v: toString v.source)
          (attrValues cfg));
        badFilesStr = toString badFiles;
      in
        {
          assertion = badFiles == [];
          message = "Source file names must not start with '.': ${badFilesStr}";
        })
    ];

    # This verifies that the links we are about to create will not
    # overwrite an existing file.
    home.activation.checkLinkTargets = dagEntryBefore ["writeBoundary"] (
      let
        pattern = "-home-manager-files/";
        check = pkgs.writeText "check" ''
          . ${./lib-bash/color-echo.sh}

          newGenFiles="$1"
          shift
          for sourcePath in "$@" ; do
            relativePath="''${sourcePath#$newGenFiles/}"
            targetPath="$HOME/$relativePath"
            if [[ -e "$targetPath" \
                && ! "$(readlink "$targetPath")" =~ "${pattern}" ]] ; then
              errorEcho "Existing file '$targetPath' is in the way"
              collision=1
            fi
          done

          if [[ -v collision ]] ; then
            errorEcho "Please move the above files and try again"
            exit 1
          fi
        '';
      in
      ''
        function checkNewGenCollision() {
          local newGenFiles
          newGenFiles="$(readlink -e "$newGenPath/home-files")"
          find "$newGenFiles" -type f -print0 -or -type l -print0 \
                  | xargs -0 bash ${check} "$newGenFiles"
        }

        checkNewGenCollision || exit 1
      ''
    );

    home.activation.linkGeneration = dagEntryAfter ["writeBoundary"] (
      let
        pattern = "-home-manager-files/";

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
          . ${./lib-bash/color-echo.sh}

          newGenFiles="$1"
          oldGenFiles="$2"
          shift 2
          for sourcePath in "$@" ; do
            relativePath="''${sourcePath#$oldGenFiles/}"
            targetPath="$HOME/$relativePath"
            if [[ -e "$newGenFiles/$relativePath" ]] ; then
              $VERBOSE_ECHO "Checking $targetPath: exists"
            elif [[ ! "$(readlink "$targetPath")" =~ "${pattern}" ]] ; then
              warnEcho "Path '$targetPath' not link into Home Manager generation. Skipping delete."
            else
              $VERBOSE_ECHO "Checking $targetPath: gone (deleting)"
              $DRY_RUN_CMD rm $VERBOSE_ARG "$targetPath"

              # Recursively delete empty parent directories.
              targetDir="$(dirname "$relativePath")"
              if [[ "$targetDir" != "." ]] ; then
                pushd "$HOME" > /dev/null

                # Call rmdir with a relative path excluding $HOME.
                # Otherwise, it might try to delete $HOME and exit
                # with a permission error.
                $DRY_RUN_CMD rmdir $VERBOSE_ARG \
                    -p --ignore-fail-on-non-empty \
                    "$targetDir"

                popd > /dev/null
              fi
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
            $DRY_RUN_CMD ln -Tsf $VERBOSE_ARG $(basename "$newGenProfilePath") "$genProfilePath"
            $DRY_RUN_CMD ln -Tsf $VERBOSE_ARG "$newGenPath" "$newGenGcPath"
          else
            echo "No change so reusing latest profile generation $oldGenNum"
          fi

          linkNewGen
          cleanOldGen
        ''
    );

    home-files = pkgs.stdenv.mkDerivation {
      name = "home-manager-files";

      phases = [ "installPhase" ];

      installPhase =
        "mkdir -p $out\n" +
        concatStringsSep "\n" (
          mapAttrsToList (n: v:
            ''
              target="$(realpath -m "$out/${v.target}")"

              # Target file must be within $HOME.
              if [[ ! "$target" =~ "$out" ]] ; then
                echo "Error installing file '${v.target}' outside \$HOME" >&2
                exit 1
              fi

              if [ -d "${v.source}" ]; then
                mkdir -p "$(dirname "$out/${v.target}")"
                ln -s "${v.source}" "$target"
              else
                install -D -m${v.mode} "${v.source}" "$target"
              fi
            ''
          ) cfg
        );
    };
  };
}
