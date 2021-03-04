{ config, lib, pkgs, ... }:

{
  config = {
    qt = {
      enable = true;
      platformTheme = "gtk";
    };

    nmt.script = ''
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_QPA_PLATFORMTHEME="gtk2"'
    '';
  };
}
