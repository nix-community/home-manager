{
  pkgs,
  config,
  lib,
  ...
}:

let

  cfg =
    let
      allFiles = lib.attrValues config.home.file;
      enabledFiles = lib.filter (f: f.enable) allFiles;

      # We sort to ascending target path length. This ensures that a directory
      # end up earlier in the list so that we can more easily detect when
      # another file is placed inside this directory.
      #
      # Specifically, we want to detect two cases:
      #
      # - A directory is symlinked to the target, attempting to place a file
      #   inside this directory is an error since it would entail modifying the
      #   source directory.
      #
      # - A directory is recursively symlinked to the target, attempting to
      #   place a file inside this directory is allowed. If the placed file
      #   overlaps with a path from the recursively symlinked directory it will
      #   override the one from the directory.
      sortedFiles = lib.lists.sortOn (f: lib.stringLength f.target) enabledFiles;
    in
    sortedFiles;

  inherit (config.home) fileOverlapResolution homeDirectory;

  inherit
    (
      (import lib/file-type.nix {
        inherit homeDirectory lib pkgs;
      })
    )
    fileType
    ;

  sourceStorePath =
    file:
    let
      sourcePath = toString file.source;
      sourceName = config.lib.strings.storeFileName (baseNameOf sourcePath);
    in
    if builtins.hasContext sourcePath then
      file.source
    else
      builtins.path {
        path = file.source;
        name = sourceName;
      };

in

{
  options = {
    home.file = lib.mkOption {
      description = "Attribute set of files to link into the user home.";
      default = { };
      type = fileType "home.file" "{env}`HOME`" homeDirectory;
    };

    home.fileOverlapResolution = lib.mkOption {
      type = lib.types.enum [
        "ignore"
        "error"
        "override"
      ];
      default = "ignore";
      visible = false;
      description = ''
        Determines how to handle a conflict between a file occurring due to
        recursive symlinking and regular symlinking.

        The default, "ignore", is the one most closely matching the legacy
        behavior. It keeps the recursively linked file and ignores the regularly
        symlinked one. The "error" alternative causes the `file-files` build to
        error out. The "override" alternative replaces the recursively linked
        file by the regularly linked one.

        This option should be considered experimental and is therefore hidden
        from documentation at this time.
      '';
    };

    home-files = lib.mkOption {
      type = lib.types.package;
      internal = true;
      description = "Package to contain all home files";
    };
  };

  config = {
    assertions = [
      (
        let
          dups = lib.attrNames (
            lib.filterAttrs (_n: v: v > 1) (
              lib.foldAttrs (acc: v: acc + v) 0 (map (v: { ${v.target} = 1; }) cfg)
            )
          );
          dupsStr = lib.concatStringsSep ", " dups;
        in
        {
          assertion = dups == [ ];
          message = ''
            Conflicting managed target files: ${dupsStr}

            This may happen, for example, if you have a configuration similar to

                home.file = {
                  conflict1 = { source = ./foo.nix; target = "baz"; };
                  conflict2 = { source = ./bar.nix; target = "baz"; };
                }'';
        }
      )
    ];

    #  Using this function it is possible to make `home.file` create a
    #  symlink to a path outside the Nix store. For example, a Home Manager
    #  configuration containing
    #
    #      `home.file."foo".source = config.lib.file.mkOutOfStoreSymlink ./bar;`
    #
    #  would upon activation create a symlink `~/foo` that points to the
    #  absolute path of the `bar` file relative the configuration file.
    lib.file.mkOutOfStoreSymlink =
      path:
      let
        pathStr = toString path;
        name = lib.hm.strings.storeFileName (baseNameOf pathStr);
      in
      pkgs.runCommandLocal name { } "ln -s ${lib.escapeShellArg pathStr} $out";

    # This verifies that the links we are about to create will not
    # overwrite an existing file.
    home.activation.checkLinkTargets = lib.hm.dag.entryBefore [ "writeBoundary" ] (
      let
        # Paths that should be forcibly overwritten by Home Manager.
        # Caveat emptor!
        forcedPaths = lib.concatMapStringsSep " " (p: ''"$HOME"/${lib.escapeShellArg p}'') (
          map (v: v.target) (lib.filter (v: v.force) cfg)
        );

        storeDir = lib.escapeShellArg builtins.storeDir;

        check = pkgs.replaceVars ./files/check-link-targets.sh {
          inherit (config.lib.bash) initHomeManagerLib;
          inherit forcedPaths storeDir;
        };
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
    # 2. Symlink files from the new generation into $HOME.
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
    home.activation.linkGeneration = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      let
        link = pkgs.writeShellScript "link" ''
          ${config.lib.bash.initHomeManagerLib}

          newGenFiles="$1"
          shift
          for sourcePath in "$@" ; do
            relativePath="''${sourcePath#$newGenFiles/}"
            targetPath="$HOME/$relativePath"
            if [[ -e "$targetPath" && ! -L "$targetPath" ]] ; then
              if [[ -n "$HOME_MANAGER_BACKUP_COMMAND" ]] ; then
                verboseEcho "Running $HOME_MANAGER_BACKUP_COMMAND $targetPath."
                run $HOME_MANAGER_BACKUP_COMMAND "$targetPath" || errorEcho "Running `$HOME_MANAGER_BACKUP_COMMAND` on '$targetPath' failed."
              elif [[ -n "$HOME_MANAGER_BACKUP_EXT" ]] ; then
                # The target exists, back it up
                backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
                if [[ -e "$backup" && -n "$HOME_MANAGER_BACKUP_OVERWRITE" ]]; then
                  run rm $VERBOSE_ARG "$backup"
                fi
                run mv $VERBOSE_ARG "$targetPath" "$backup" || errorEcho "Moving '$targetPath' failed!"
              fi
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
          homeFilePattern="$(readlink -e ${lib.escapeShellArg builtins.storeDir})/*-home-manager-files/*"

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
        linkNewGen
      ''
    );

    home.activation.checkFilesChanged = lib.hm.dag.entryBefore [ "linkGeneration" ] (
      let
        homeDirArg = lib.escapeShellArg homeDirectory;
      in
      ''
        function _cmp() {
          if [[ -d $1 && -d $2 ]]; then
            diff -rq "$1" "$2" &> /dev/null
          else
            cmp --quiet "$1" "$2"
          fi
        }
        declare -A changedFiles
      ''
      + lib.concatMapStrings (
        v:
        let
          sourceArg = lib.escapeShellArg (sourceStorePath v);
          targetArg = lib.escapeShellArg v.target;
        in
        ''
          _cmp ${sourceArg} ${homeDirArg}/${targetArg} \
            && changedFiles[${targetArg}]=0 \
            || changedFiles[${targetArg}]=1
        ''
      ) (lib.filter (v: v.onChange != "") cfg)
      + ''
        unset -f _cmp
      ''
    );

    home.activation.onFilesChange = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      lib.concatMapStrings (v: ''
        if (( ''${changedFiles[${lib.escapeShellArg v.target}]} == 1 )); then
          if [[ -v DRY_RUN || -v VERBOSE ]]; then
            echo "Running onChange hook for" ${lib.escapeShellArg v.target}
          fi
          if [[ ! -v DRY_RUN ]]; then
            ${v.onChange}
          fi
        fi
      '') (lib.filter (v: v.onChange != "") cfg)
    );

    # Symlink directories and files that have the right execute bit.
    # Copy files that need their execute bit changed.
    home-files =
      pkgs.runCommandLocal "home-manager-files"
        {
          nativeBuildInputs = [ pkgs.lndir ];
        }
        (
          ''
            mkdir -p $out

            # Needed in case /nix is a symbolic link.
            realOut="$(realpath -m "$out")"

            # An associative array of previously handled target paths. This is
            # the path handled for the declared file in home.file. That is, if a
            # file has been specified as recursive, then this array will only
            # contain the recursion root, not the visited files.
            declare -A seenTargets

            function insertFile() {
              local source="$1"
              local relTarget="$2"
              local executable="$3"
              local recursive="$4"
              local ignorelinks="$5"

              # If the target has already been seen then we have a collision. Note, this
              # should not happen due to the assertion found in the 'files' module.
              # We therefore simply log the conflict and otherwise ignore it,
              # mainly to make the `files-target-conflict` test work as expected.
              if [[ ''${seenTargets["$relTarget"]} ]]; then
                echo "File conflict for file '$relTarget'" >&2
                return
              fi

              # If the path already exists as a non-directory, then we are
              # conflicting with a file from a recursively linked directory. Log
              # this fact and error out the build.
              if [[ -e "$realOut/$relTarget" && ! -d "$realOut/$relTarget" ]]; then
                echo "$relTarget conflicts with recursively symlinked file" >&2
                ${
                  if fileOverlapResolution == "ignore" then
                    "return"
                  else if fileOverlapResolution == "error" then
                    "exit 1"
                  else if fileOverlapResolution == "override" then
                    ''rm "$realOut/$relTarget"''
                  else
                    abort ''Unknown file resolution overlap "${fileOverlapResolution}"''
                }
              fi

              # Record that we have seen this target file.
              seenTargets["$relTarget"]=1

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
                  if [[ $ignorelinks ]]; then
                    lndir -silent -ignorelinks "$source" "$target"
                  else
                    lndir -silent "$source" "$target"
                  fi
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
          ''
          + lib.concatStrings (
            map (v: ''
              insertFile ${
                lib.escapeShellArgs [
                  (sourceStorePath v)
                  v.target
                  (if v.executable == null then "inherit" else toString v.executable)
                  (toString v.recursive)
                  (toString v.ignorelinks)
                ]
              }
            '') cfg
          )
        );
  };
}
