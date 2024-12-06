{ config, lib, pkgs, ... }:

with lib;

let
  homeDir = config.home.homeDirectory;
  fontsEnv = (pkgs.buildEnv {
    name = "home-manager-fonts";
    paths = config.home.packages;
    pathsToLink = "/share/fonts";
  }).overrideAttrs (old: { __noChroot = config.home.buildEnvWithNoChroot; });
  fonts = "${fontsEnv}/share/fonts";
  installDir = "${homeDir}/Library/Fonts/HomeManager";
in {
  # macOS won't recognize symlinked fonts
  config = mkIf pkgs.stdenv.hostPlatform.isDarwin {
    home.file."Library/Fonts/.home-manager-fonts-version" = {
      text = "${fontsEnv}";
      onChange = ''
        run mkdir -p ${escapeShellArg installDir}
        run ${pkgs.rsync}/bin/rsync $VERBOSE_ARG -acL --chmod=u+w --delete \
          ${escapeShellArgs [ "${fonts}/" installDir ]}
      '';
    };
  };
}
