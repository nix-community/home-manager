{
  pkgs,
  config,
  lib,
  putter,
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

  putterStatePath = "${config.xdg.stateHome}/home-manager/putter-state.json";

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

    home.internal = {
      filePutterConfig = lib.mkOption {
        type = lib.types.package;
        internal = true;
        description = "Putter configuration.";
      };
    };
  };

  config = {
    assertions = [
      (
        let
          dups = lib.attrNames (
            lib.filterAttrs (n: v: v > 1) (
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
    home.activation.checkLinkTargets = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      ${lib.getExe putter} check -v \
        --state-file "${putterStatePath}" \
        ${config.home.internal.filePutterConfig}
    '';

    home.activation.linkGeneration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.getExe putter} apply $VERBOSE_ARG -v ''${DRY_RUN:+--dry-run} \
        --state-file "${putterStatePath}" \
        ${config.home.internal.filePutterConfig}
    '';

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

    home.internal.filePutterConfig =
      let
        putter = import ./lib/putter.nix { inherit lib; };
        manifest = putter.mkPutterManifest {
          inherit putterStatePath;
          sourceBaseDirectory = config.home-files;
          targetBaseDirectory = config.home.homeDirectory;
          fileEntries = cfg;
        };
      in
      pkgs.writeText "hm-putter.json" manifest;

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
