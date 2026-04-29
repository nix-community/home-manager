{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.programs.man;
  cfgManDb = config.programs.man.man-db;
in
{
  options.programs.man.man-db = {
    enable = mkEnableOption "man-db as the man page viewer" // {
      default = true;
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
  };

  config = mkIf (cfg.enable && cfgManDb.enable) {
    # This is mostly copy/pasted/adapted from NixOS' documentation.nix.
    home.file = mkIf (cfg.generateCaches && cfg.package != null) {
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
        + lib.optionalString (cfgManDb.extraConfig != "") "\n${cfgManDb.extraConfig}";
    };
  };
}
