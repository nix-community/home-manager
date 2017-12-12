{ pkgs, config, lib, ... }:

with lib;
with import ./lib/dag.nix { inherit lib; };

let

  cfg = config.home.file;

  homeDirectory = config.home.homeDirectory;

  fileType = (import lib/file-type.nix {
    inherit homeDirectory lib pkgs;
  }).fileType;

  # A symbolic link whose target path matches this pattern will be
  # considered part of a Home Manager generation.
  homeFilePattern = "${builtins.storeDir}/*-home-manager-files/*";

in

{
  options = {
    home.file = mkOption {
      description = "Attribute set of files to link into the user home.";
      default = {};
      type = fileType "<envar>HOME</envar>" homeDirectory;
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
        check = pkgs.writeText "check" ''
          . ${./lib-bash/color-echo.sh}

          newGenFiles="$1"
          shift
          for sourcePath in "$@" ; do
            relativePath="''${sourcePath#$newGenFiles/}"
            targetPath="$HOME/$relativePath"
            if [[ -e "$targetPath" \
                && ! "$(readlink "$targetPath")" == ${homeFilePattern} ]] ; then
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

    # This activation script will
    #
    # 1. Remove files from the old generation that are not in the new
    #    generation.
    #
    # 2. Switch over the Home Manager gcroot and current profile
    #    links.
    #
    # 3. Symlink files from the new generation into $HOME.
    #
    # This order is needed to ensure that we always know which links
    # belong to which generation. Specifically, if we're moving from
    # generation A to generation B having sets of home file links FA
    # and FB, respectively then cleaning before linking produces state
    # transitions similar to
    #
    #      FA   →   FA ∩ FB   →   (FA ∩ FB) ∪ FB = FB
    #
    # and a failure during the intermediate state FA ∩ FB will not
    # result in lost links because this set of links are in both the
    # source and target generation.
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
          . ${./lib-bash/color-echo.sh}

          newGenFiles="$1"
          shift 1
          for relativePath in "$@" ; do
            targetPath="$HOME/$relativePath"
            if [[ -e "$newGenFiles/$relativePath" ]] ; then
              $VERBOSE_ECHO "Checking $targetPath: exists"
            elif [[ ! "$(readlink "$targetPath")" == ${homeFilePattern} ]] ; then
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
            echo "Creating home file links in $HOME"

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

            # Apply the cleanup script on each leaf in the old
            # generation. The find command below will print the
            # relative path of the entry.
            find "$oldGenFiles" '(' -type f -or -type l ')' -printf '%P\0' \
              | xargs -0 bash ${cleanup} "$newGenFiles"
          }

          cleanOldGen

          if [[ ! -v oldGenPath || "$oldGenPath" != "$newGenPath" ]] ; then
            echo "Creating profile generation $newGenNum"
            $DRY_RUN_CMD ln -Tsf $VERBOSE_ARG "$newGenPath" "$newGenProfilePath"
            $DRY_RUN_CMD ln -Tsf $VERBOSE_ARG $(basename "$newGenProfilePath") "$genProfilePath"
            $DRY_RUN_CMD ln -Tsf $VERBOSE_ARG "$newGenPath" "$newGenGcPath"
          else
            echo "No change so reusing latest profile generation $oldGenNum"
          fi

          linkNewGen
        ''
    );

    home-files = pkgs.stdenv.mkDerivation {
      name = "home-manager-files";

      nativeBuildInputs = [ pkgs.xlibs.lndir ];

      # Symlink directories and files that have the right execute bit.
      # Copy files that need their execute bit changed.
      buildCommand = ''
        mkdir -p $out

        function insertFile() {
          local source="$1"
          local relTarget="$2"
          local executable="$3"
          local recursive="$4"

          # Figure out the real absolute path to the target.
          local target
          target="$(realpath -m "$out/$relTarget")"

          # Target path must be within $HOME.
          if [[ ! $target == $out* ]] ; then
            echo "Error installing file '$relTarget' outside \$HOME" >&2
            exit 1
          fi

          mkdir -p "$(dirname "$target")"
          if [[ -d $source ]]; then
            if [[ $recursive ]]; then
              mkdir -p "$target"
              lndir -silent "$source" "$target"
            else
              ln -s "$source" "$target"
            fi
          else
            [[ -x $source ]] && isExecutable=1 || isExecutable=""

            # Link the file into the home file directory if possible,
            # i.e., if the executable bit of the source is the same we
            # expect for the target. Otherwise, we copy the file and
            # set the executable bit to the expected value.
            if [[ $executable == inherit || $isExecutable == $executable ]]; then
              ln -s "$source" "$target"
            else
              cp "$source" "$target"

              if [[ $executable == inherit ]]; then
                # Don't change file mode if it should match the source.
                :
              elif [[ $executable ]]; then
                chmod +x "$target"
              else
                chmod -x "$target"
              fi
            fi
          fi
        }
      '' + concatStrings (
        mapAttrsToList (n: v: ''
          insertFile "${v.source}" \
                     "${v.target}" \
                     "${if v.executable == null
                        then "inherit"
                        else builtins.toString v.executable}" \
                     "${builtins.toString v.recursive}"
        '') cfg
      );
    };
  };
}
