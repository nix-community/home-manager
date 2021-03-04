{ config, lib, pkgs, ... }:

{
  config = {
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = {
        name = "adwaita";
        package = pkgs.dummyTheme;
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        dummyTheme = pkgs.runCommandLocal "theme" { } "mkdir $out";
      })
    ];

    nmt.script = ''
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_QPA_PLATFORMTHEME="gnome"'
      assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
        'QT_STYLE_OVERRIDE="adwaita"'
    '';
  };
}
