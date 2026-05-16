{ config, ... }:
# A shortcut with no modifiers produces a bare key name in the accel string.
{
  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    keyboardShortcuts = {
      "<Actions>/gimp-app-quit" = {
        modifiers = [ ];
        key = "q";
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/GIMP/3.0/menurc"
    assertFileRegex "home-files/.config/GIMP/3.0/menurc" \
      'gimp-app-quit" "q"'
  '';
}
