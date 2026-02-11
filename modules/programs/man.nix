{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.programs.man;
in
{
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

      generateCaches = mkOption {
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
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional (
      cfg.generateCaches && cfg.package == null
    ) "programs.man.generateCaches has no effect when programs.man.package is null";

    home.packages = lib.optional (cfg.package != null) cfg.package;
    home.extraOutputsToInstall = [ "man" ];

    # This is mostly copy/pasted/adapted from NixOS' documentation.nix.
    home.file = lib.mkIf (cfg.generateCaches && cfg.package != null) {
      ".manpath".text =
        let
          # Generate a directory containing installed packages' manpages.
          manualPages = pkgs.buildEnv {
            name = "man-paths";
            paths = config.home.packages;
            pathsToLink = [ "/share/man" ];
            extraOutputsToInstall = [ "man" ];
            ignoreCollisions = true;
          };

          # Generate a database of all manpages in ${manualPages}.
          manualCache =
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
        in
        ''
          MANDB_MAP ${config.home.profileDirectory}/share/man ${manualCache}
        ''
        + lib.optionalString (cfg.extraConfig != "") "\n${cfg.extraConfig}";
    };
  };
}
