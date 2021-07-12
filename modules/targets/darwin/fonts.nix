{ config, lib, pkgs, ... }:

with lib;

let
  homeDir = config.home.homeDirectory;
  fontsEnv = pkgs.buildEnv {
    name = "home-manager-fonts";
    paths = config.home.packages;
    pathsToLink = "/share/fonts";
  };
  fonts = "${fontsEnv}/share/fonts";
in {
  # macOS won't recognize symlinked fonts
  config = mkIf pkgs.hostPlatform.isDarwin {
    home.activation.copyFonts = hm.dag.entryAfter [ "writeBoundary" ] ''
      copyFonts() {
        rm -rf ${homeDir}/Library/Fonts/HomeManager || :

        local f
        find -L "${fonts}" -type f -printf '%P\0' | while IFS= read -rd "" f; do
          $DRY_RUN_CMD install $VERBOSE_ARG -Dm644 -T \
            "${fonts}/$f" "${homeDir}/Library/Fonts/HomeManager/$f"
        done
      }
      copyFonts
    '';
  };
}
