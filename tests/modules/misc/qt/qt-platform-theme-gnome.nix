{ pkgs, ... }:

{
  qt = {
    enable = true;
    platformTheme = {
      name = "gnome";
      package = [
        pkgs.qgnomeplatform
        pkgs.qgnomeplatform-qt6
      ];
    };
    style.name = "adwaita";
  };

  nmt.script = ''
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QT_QPA_PLATFORMTHEME="gnome"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'QT_STYLE_OVERRIDE="adwaita"'
  '';
}
