{ pkgs, activationPkgs, config, lib, ... }:

with lib;

let

  cfg = filterAttrs (n: f: f.enable) config.home.file;

  homeDirectory = config.home.homeDirectory;

  fileType = (import lib/file-type.nix {
    inherit homeDirectory lib pkgs;
  }).fileType;

  sourceStorePath = file:
    let
      sourcePath = toString file.source;
      sourceName = config.lib.strings.storeFileName (baseNameOf sourcePath);
    in
      if builtins.hasContext sourcePath
      then file.source
      else builtins.path { path = file.source; name = sourceName; };

in

{
  options = {
    home.file = mkOption {
      description = "Attribute set of files to link into the user home.";
      default = {};
      type = fileType "home.file" "{env}`HOME`" homeDirectory;
    };

    home-files = mkOption {
      type = types.package;
      internal = true;
      description = "Package to contain all home files";
    };
  };

  config = {
    assertions = [(
      let
        dups =
          attrNames
            (filterAttrs (n: v: v > 1)
            (foldAttrs (acc: v: acc + v) 0
            (mapAttrsToList (n: v: { ${v.target} = 1; }) cfg)));
        dupsStr = concatStringsSep ", " dups;
      in {
        assertion = dups == [];
        message = ''
          Conflicting managed target files: ${dupsStr}

          This may happen, for example, if you have a configuration similar to

              home.file = {
                conflict1 = { source = ./foo.nix; target = "baz"; };
                conflict2 = { source = ./bar.nix; target = "baz"; };
              }'';
      })
    ];

    lib.file.mkOutOfStoreSymlink = path:
      let
        pathStr = toString path;
        name = hm.strings.storeFileName (baseNameOf pathStr);
      in
        pkgs.runCommandLocal name {} ''ln -s ${escapeShellArg pathStr} $out'';

    # This verifies that the links we are about to create will not
    # overwrite an existing file.
    home.activation.checkLinkTargets = hm.dag.entryBefore ["writeBoundary"] (
      let
        # Paths that should be forcibly overwritten by Home Manager.
        # Caveat emptor!
        forcedPaths =
          concatMapStringsSep " " (p: ''"$HOME"/${escapeShellArg p}'')
            (mapAttrsToList (n: v: v.target)
            (filterAttrs (n: v: v.force) cfg));

        check = activationPkgs.writeText "check" ''
          ${config.lib.bash.initHomeManagerLib}

          # A symbolic link whose target path matches this pattern will be
          # considered part of a Home Manager generation.
          homeFilePattern="$(readlink -e ${escapeShellArg builtins.storeDir})/*-home-manager-files/*"

          forcedPaths=(${forcedPaths})

          newGenFiles="$1"
          shift
          for sourcePath in "$@" ; do
            relativePath="''${sourcePath#$newGenFiles/}"
            targetPath="$HOME/$relativePath"

            forced=""
            for forcedPath in "''${forcedPaths[@]}"; do
              if [[ $targetPath == $forcedPath* ]]; then
                forced="yeah"
                break
              fi
            done

            if [[ -n $forced ]]; then
              verboseEcho "Skipping collision check for $targetPath"
            elif [[ -e "$targetPath" \
                && ! "$(readlink "$targetPath")" == $homeFilePattern ]] ; then
              # The target file already exists and it isn't a symlink owned by Home Manager.
              if cmp -s "$sourcePath" "$targetPath"; then
                # First compare the files' content. If they're equal, we're fine.
                warnEcho "Existing file '$targetPath' is in the way of '$sourcePath', will be skipped since they are the same"
              elif [[ ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_EXT" ]] ; then
                # Next, try to move the file to a backup location if configured and possible
                backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
                if [[ -e "$backup" ]]; then
                  errorEcho "Existing file '$backup' would be clobbered by backing up '$targetPath'"
                  collision=1
                else
                  warnEcho "Existing file '$targetPath' is in the way of '$sourcePath', will be moved to '$backup'"
                fi
              else
                # Fail if nothing else works
                errorEcho "Existing file '$targetPath' is in the way of '$sourcePath'"
                collision=1
              fi
            fi
          done

          if [[ -v collision ]] ; then
            errorEcho "Please move the above files and try again or use 'home-manager switch -b backup' to back up existing files automatically."
            exit 1
          fi
        '';
      in
      ''
        function checkNewGenCollision() {
          local newGenFiles
          newGenFiles="$(readlink -e "$newGenPath/home-files")"
          find "$newGenFiles" \( -type f -or -type l \) \
              -exec bash ${check} "$newGenFiles" {} +
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
    home.activation.linkGeneration = hm.dag.entryAfter ["writeBoundary"] (
      let
        link = activationPkgs.writeShellScript "link" ''
          ${config.lib.bash.initHomeManagerLib}

          newGenFiles="$1"
          shift
          for sourcePath in "$@" ; do
            relativePath="''${sourcePath#$newGenFiles/}"
            targetPath="$HOME/$relativePath"
            if [[ -e "$targetPath" && ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_EXT" ]] ; then
              # The target exists, back it up
              backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
              run mv $VERBOSE_ARG "$targetPath" "$backup" || errorEcho "Moving '$targetPath' failed!"
            fi

            if [[ -e "$targetPath" && ! -L "$targetPath" ]] && cmp -s "$sourcePath" "$targetPath" ; then
              # The target exists but is identical – don't do anything.
              verboseEcho "Skipping '$targetPath' as it is identical to '$sourcePath'"
            else
              # Place that symlink, --force
              # This can still fail if the target is a directory, in which case we bail out.
              run mkdir -p $VERBOSE_ARG "$(dirname "$targetPath")"
              run ln -Tsf $VERBOSE_ARG "$sourcePath" "$targetPath" || exit 1
            fi
          done
        '';

        cleanup = pkgs.writeShellScript "cleanup" ''
          ${config.lib.bash.initHomeManagerLib}

          # A symbolic link whose target path matches this pattern will be
          # considered part of a Home Manager generation.
          homeFilePattern="$(readlink -e ${escapeShellArg builtins.storeDir})/*-home-manager-files/*"

          newGenFiles="$1"
          shift 1
          for relativePath in "$@" ; do
            targetPath="$HOME/$relativePath"
            if [[ -e "$newGenFiles/$relativePath" ]] ; then
              verboseEcho "Checking $targetPath: exists"
            elif [[ ! "$(readlink "$targetPath")" == $homeFilePattern ]] ; then
              warnEcho "Path '$targetPath' does not link into a Home Manager generation. Skipping delete."
            else
              verboseEcho "Checking $targetPath: gone (deleting)"
              run rm $VERBOSE_ARG "$targetPath"

              # Recursively delete empty parent directories.
              targetDir="$(dirname "$relativePath")"
              if [[ "$targetDir" != "." ]] ; then
                pushd "$HOME" > /dev/null

                # Call rmdir with a relative path excluding $HOME.
                # Otherwise, it might try to delete $HOME and exit
                # with a permission error.
                run rmdir $VERBOSE_ARG \
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
            _i "Creating home file links in %s" "$HOME"

            local newGenFiles
            newGenFiles="$(readlink -e "$newGenPath/home-files")"
            find "$newGenFiles" \( -type f -or -type l \) \
              -exec bash ${link} "$newGenFiles" {} +
          }

          function cleanOldGen() {
            if [[ ! -v oldGenPath || ! -e "$oldGenPath/home-files" ]] ; then
              return
            fi

            _i "Cleaning up orphan links from %s" "$HOME"

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
            _i "Creating profile generation %s" $newGenNum
            if [[ -e "$genProfilePath"/manifest.json ]] ; then
              # Remove all packages from "$genProfilePath"
              # `nix profile remove '.*' --profile "$genProfilePath"` was not working, so here is a workaround:
              nix profile list --profile "$genProfilePath" \
                | cut -d ' ' -f 4 \
                | xargs -rt $DRY_RUN_CMD nix profile remove $VERBOSE_ARG --profile "$genProfilePath"
              run nix profile install $VERBOSE_ARG --profile "$genProfilePath" "$newGenPath"
            else
              run nix-env $VERBOSE_ARG --profile "$genProfilePath" --set "$newGenPath"
            fi

            run --silence nix-store --realise "$newGenPath" --add-root "$newGenGcPath"
            if [[ -e "$legacyGenGcPath" ]]; then
              run rm $VERBOSE_ARG "$legacyGenGcPath"
            fi
          else
            _i "No change so reusing latest profile generation %s" "$oldGenNum"
          fi

          linkNewGen
        ''
    );

    home.activation.checkFilesChanged = hm.dag.entryBefore ["linkGeneration"] (
      let
        homeDirArg = escapeShellArg homeDirectory;
      in ''
        function _cmp() {
          if [[ -d $1 && -d $2 ]]; then
            diff -rq "$1" "$2" &> /dev/null
          else
            cmp --quiet "$1" "$2"
          fi
        }
        declare -A changedFiles
      '' + concatMapStrings (v:
        let
          sourceArg = escapeShellArg (sourceStorePath v);
          targetArg = escapeShellArg v.target;
        in ''
          _cmp ${sourceArg} ${homeDirArg}/${targetArg} \
            && changedFiles[${targetArg}]=0 \
            || changedFiles[${targetArg}]=1
        '') (filter (v: v.onChange != "") (attrValues cfg))
      + ''
        unset -f _cmp
      ''
    );

    home.activation.onFilesChange = hm.dag.entryAfter ["linkGeneration"] (
      concatMapStrings (v: ''
        if (( ''${changedFiles[${escapeShellArg v.target}]} == 1 )); then
          if [[ -v DRY_RUN || -v VERBOSE ]]; then
            echo "Running onChange hook for" ${escapeShellArg v.target}
          fi
          if [[ ! -v DRY_RUN ]]; then
            ${v.onChange}
          fi
        fi
      '') (filter (v: v.onChange != "") (attrValues cfg))
    );

    # Symlink directories and files that have the right execute bit.
    # Copy files that need their execute bit changed.
    home-files = pkgs.runCommandLocal
      "home-manager-files"
      {
        nativeBuildInputs = [ pkgs.xorg.lndir ];
      }
      (''
        mkdir -p $out

        # Needed in case /nix is a symbolic link.
        realOut="$(realpath -m "$out")"

        function insertFile() {
          local source="$1"
          local relTarget="$2"
          local executable="$3"
          local recursive="$4"

          # If the target already exists then we have a collision. Note, this
          # should not happen due to the assertion found in the 'files' module.
          # We therefore simply log the conflict and otherwise ignore it, mainly
          # to make the `files-target-config` test work as expected.
          if [[ -e "$realOut/$relTarget" ]]; then
            echo "File conflict for file '$relTarget'" >&2
            return
          fi

          # Figure out the real absolute path to the target.
          local target
          target="$(realpath -m "$realOut/$relTarget")"

          # Target path must be within $HOME.
          if [[ ! $target == $realOut* ]] ; then
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
          insertFile ${
            escapeShellArgs [
              (sourceStorePath v)
              v.target
              (if v.executable == null
               then "inherit"
               else toString v.executable)
              (toString v.recursive)
            ]}
        '') cfg
      ));
  };
}
