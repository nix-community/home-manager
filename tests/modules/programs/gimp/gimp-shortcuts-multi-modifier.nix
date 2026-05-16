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
      "<Actions>/edit/edit-undo" = {
        modifiers = [
          "Primary"
          "Shift"
        ];
        key = "z";
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/GIMP/3.0/menurc"
    assertFileRegex "home-files/.config/GIMP/3.0/menurc" \
      'edit-undo.*Primary.*Shift.*z'
  '';
}
