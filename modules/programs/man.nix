{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.programs.man;

  # Generate a directory containing installed packages' manpages.
  manualPages = pkgs.buildEnv {
    name = "man-paths";
    paths = config.home.packages;
    pathsToLink = [ "/share/man" ];
    extraOutputsToInstall = [ "man" ];
    ignoreCollisions = true;
  };

in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "man" "generateCaches" ]
      [ "programs" "man" "cache" "enable" ]
    )
  ];

  options = {
    programs.man = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable manual pages and the {command}`man`
          command. This also includes "man" outputs of all
          `home.packages`.
        '';
      };

      package = mkOption {
        type = with types; nullOr package;
        default =
          if pkgs.stdenv.isDarwin && lib.versionAtLeast config.home.stateVersion "26.05" then
            null
          else
            pkgs.man;
        defaultText = lib.literalExpression ''
          if pkgs.stdenv.isDarwin && lib.versionAtLeast config.home.stateVersion "26.05" then null else pkgs.man
        '';
        description = "The {command}`man` package to use.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Additional fields to be added to the end of the user manpath config file.";
        example = ''
          MANDATORY_MANPATH /usr/man
          SECTION 1 n l 8 3 0 2 3type 5 4 9 6 7
        '';
      };

      cache = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to generate the manual page index caches using
            {manpage}`mandb(8)`. This allows searching for a page or
            keyword using utilities like {manpage}`apropos(1)`.

            This feature is disabled by default because it slows down
            building. If you don't mind waiting a few more seconds when
            Home Manager builds a new generation, you may safely enable
            this option.
          '';
        };

        generateAtRuntime = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to generate the manual page index caches at runtime using
            a systemd service.

            ::: {.note}
            This is currently only supported on Linux.
            :::
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion =
              let
                runtimeCache = (cfg.cache.enable && cfg.cache.generateAtRuntime);
                isLinux = lib.elem pkgs.stdenv.hostPlatform.system lib.platforms.linux;
              in
              runtimeCache -> isLinux;
            message = ''
              `programs.man.cache.generateAtRuntime` is only supported on Linux.
            '';
          }
        ];

        warnings = lib.optional (
          cfg.cache.enable && cfg.package == null
        ) "programs.man.cache.enable has no effect when programs.man.package is null";
      }
      {
        home.packages = lib.optional (cfg.package != null) cfg.package;
        home.extraOutputsToInstall = [ "man" ];
      }
      (lib.mkIf (cfg.cache.enable && cfg.package != null) {
        # This is mostly copy/pasted/adapted from NixOS' documentation.nix.
        home.file.".manpath".text =
          let
            # Generate a database of all manpages in ${manualPages}.
            manualCache' =
              pkgs.runCommandLocal "man-cache"
                {
                  nativeBuildInputs = [ cfg.package ];
                }
                ''
                  # Generate a temporary man.conf so mandb knows where to
                  # write cache files.
                  echo "MANDB_MAP ${manualPages}/share/man $out" > man.conf

                  # Run mandb to generate cache files:
                  mandb -C man.conf --no-straycats --create \
                    ${manualPages}/share/man
                '';
            manualCache =
              if (!cfg.cache.generateAtRuntime) then
                manualCache'
              else
                # FIXME: relies on this path being correct
                "${config.xdg.cacheHome}/man/hm-mandb";

          in
          ''
            MANDB_MAP ${config.home.profileDirectory}/share/man ${manualCache}
          ''
          + lib.optionalString (cfg.extraConfig != "") "\n${cfg.extraConfig}";
      })
      (lib.mkIf (cfg.cache.enable && cfg.cache.generateAtRuntime && cfg.package != null) {
        systemd.user.services.mandb = {
          Unit = {
            Description = ""; # FIXME
            Documentation = "man:mandb(8)";
            X-Restart-Triggers = [
              manualPages
            ];
          };
          Service = {
            ExecStart =
              pkgs.writeShellApplication
                {
                  runtimeInputs = [
                    cfg.package
                    pkgs.rsync
                  ];
                }
                ''
                  rsync \
                    --checksum --recursive --copy-links --delete --no-times --no-perms --chmod=+w \
                    ${manualPages}/share/man/ "$CACHE_DIRECTORY/hm-manpages"

                  echo "MANDB_MAP $CACHE_DIRECTORY/hm-manpages $CACHE_DIRECTORY/hm-mandb" \
                    > "$RUNTIME_DIRECTORY/man.conf"

                  mandb -C "$RUNTIME_DIRECTORY/man.conf" -q
                '';
            CacheDirectory = "man";
            RuntimeDirectory = "mandb";
            BindReadOnlyPaths = [ "/dev/null:/etc/man_db.conf" ]; # mandb will still read /etc/man_db.conf if it exists, even when setting -C path/to/config.conf
            ProtectSystem = "strict";
          };
          Install.WantedBy = [ "default.target" ];
        };
      })
    ]
  );
}
