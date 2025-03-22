{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.man;
in {
  options.programs.man.man-db.enable = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Whether to enable man-db as the man page viewer.
    '';
  };

  config = mkIf cfg.man-db.enable {
    programs.man.package = mkDefault pkgs.man;

    # This is mostly copy/pasted/adapted from NixOS' documentation.nix.
    home.file = mkIf cfg.generateCaches {
      ".manpath".text = let
        # Generate a directory containing installed packages' manpages.
        manualPages = pkgs.buildEnv {
          name = "man-paths";
          paths = config.home.packages;
          pathsToLink = [ "/share/man" ];
          extraOutputsToInstall = [ "man" ];
          ignoreCollisions = true;
        };

        # Generate a database of all manpages in ${manualPages}.
        manualCache = pkgs.runCommandLocal "man-cache" {
          nativeBuildInputs = [ cfg.package ];
        } ''
          # Generate a temporary man.conf so mandb knows where to
          # write cache files.
          echo "MANDB_MAP ${manualPages}/share/man $out" > man.conf

          # Run mandb to generate cache files:
          mandb -C man.conf --no-straycats --create \
            ${manualPages}/share/man
        '';
      in ''
        MANDB_MAP ${config.home.profileDirectory}/share/man ${manualCache}
      '';
    };
  };
}
