{
  config,
  lib,
  pkgs,
  ...
}:

let
  fontsEnv = pkgs.buildEnv {
    name = "home-manager-fonts";
    paths = config.home.packages;
    pathsToLink = "/share/fonts";
  };
  fonts = "${fontsEnv}/share/fonts";
  installDir = "${config.home.homeDirectory.shell}/Library/Fonts/HomeManager";
in
{
  # macOS won't recognize symlinked fonts
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    home.file."Library/Fonts/.home-manager-fonts-version" = {
      text = "${fontsEnv}";
      onChange = ''
        run mkdir -p ${installDir}
        run ${pkgs.rsync}/bin/rsync $VERBOSE_ARG -acL --chmod=u+w --delete \
          ${lib.escapeShellArg "${fonts}/"} \
          ${installDir}
      '';
    };
  };
}
