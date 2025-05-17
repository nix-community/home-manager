{
  pkgs,
  config,
  lib,
  ...
}:

let

  cfg = lib.filterAttrs (n: f: f.enable) config.home.file;

  homeDirectory = config.home.homeDirectory;

  fileType =
    (import lib/file-type.nix {
      inherit homeDirectory lib pkgs;
    }).fileType;

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
            lib.filterAttrs (n: v: v > 1) (
              lib.foldAttrs (acc: v: acc + v) 0 (lib.mapAttrsToList (n: v: { ${v.target} = 1; }) cfg)
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
      pkgs.runCommandLocal name { } ''ln -s ${lib.escapeShellArg pathStr} $out'';

    # This verifies that the links we are about to create will not
    # overwrite an existing file.
    home.activation.checkLinkTargets = lib.hm.dag.entryBefore [ "writeBoundary" ] (
      let
        # Paths that should be forcibly overwritten by Home Manager.
        # Caveat emptor!
        forcedPaths = lib.concatMapStringsSep " " (p: ''"$HOME"/${lib.escapeShellArg p}'') (
          lib.mapAttrsToList (n: v: v.target) (lib.filterAttrs (n: v: v.force) cfg)
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
        link = pkgs.replaceVars ./files/link.sh {
          inherit (config.lib.bash) initHomeManagerLib;
        };

        storeDir = lib.escapeShellArg builtins.storeDir;

        cleanup = pkgs.replaceVars ./files/cleanup.sh {
          inherit (config.lib.bash) initHomeManagerLib;
          inherit storeDir;
        };
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
      ) (lib.filter (v: v.onChange != "") (lib.attrValues cfg))
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
      '') (lib.filter (v: v.onChange != "") (lib.attrValues cfg))
    );

    # Symlink directories and files that have the right execute bit.
    # Copy files that need their execute bit changed.
    home-files = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      name = "home-manager-files";
      enableParallelBuilding = true;
      preferLocalBuild = true;
      allowSubstitutes = false;
      nativeBuildInputs = [ pkgs.xorg.lndir ];
      PATH = lib.makeBinPath finalAttrs.nativeBuildInputs;
      passAsFile = [
        "buildCommand"
        "insertFiles"
      ];
      buildCommand = ./files/home-manager-files.sh;
      insertFiles = lib.concatStrings (
        lib.mapAttrsToList (n: v: ''
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
      );
      checkPhase = ''
        ${pkgs.stdenvNoCC.shellDryRun} "$target"
      '';
    });
  };
}
