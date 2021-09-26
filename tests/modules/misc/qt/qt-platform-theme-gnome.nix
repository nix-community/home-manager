{ config, lib, pkgs, ... }:

{
  config = {
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = {
        name = "adwaita";
        package = config.lib.test.mkStubPackage { };
      };
    };

    test.stubs.qgnomeplatform = { };

    nmt.script = ''
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_QPA_PLATFORMTHEME="gnome"'
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_STYLE_OVERRIDE="adwaita"'
    '';
  };
}
