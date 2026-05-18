{ config, ... }:
{
  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    keyboardShortcuts = {
      "<Actions>/edit/edit-copy" = {
        modifiers = [ "Primary" ];
        key = "c";
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/GIMP/3.0/menurc"
    assertFileRegex "home-files/.config/GIMP/3.0/menurc" \
      'gtk_accel_path.*edit-copy.*Primary.*c'
  '';
}
