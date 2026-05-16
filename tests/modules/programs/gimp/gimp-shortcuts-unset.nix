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
      "<Actions>/file/file-quit" = {
        modifiers = [ ];
        key = "";
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/GIMP/3.0/menurc"
    assertFileRegex "home-files/.config/GIMP/3.0/menurc" \
      'file-quit" ""'
  '';
}
