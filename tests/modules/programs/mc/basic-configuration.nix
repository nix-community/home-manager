{ config, lib, ... }:

{
  programs.mc = {
    enable = true;

    settings = {
      Panels = {
        show_dot_files = false;
      };
    };

    keymapSettings = {
      panel = {
        Up = "up;ctrl-k";
      };
    };

    extensionSettings = {
      EPUB = {
        Shell = ".epub";
        Open = "fbreader %f &";
      };
    };

    panelsSettings = {
      Dirs = {
        current_is_left = false;
        other_dir = "/home";
      };
    };

    fileHighlightSettings = {
      lua = {
        extensions = "lua;luac";
      };
    };
  };

  nmt.script = ''

    mcFolder="home-files/.config/mc"

    assertFileExists "$mcFolder/ini"
    assertFileExists "$mcFolder/mc.keymap"
    assertFileExists "$mcFolder/mc.ext.ini"
    assertFileExists "$mcFolder/panels.ini"
    assertFileExists "$mcFolder/filehighlight.ini"

    assertFileContent \
      "$mcFolder/ini" \
      ${./basic-configuration}
    assertFileContent \
      "$mcFolder/mc.keymap" \
      ${./mc.keymap}
    assertFileContent \
      "$mcFolder/mc.ext.ini" \
      ${./mc.ext.ini}
    assertFileContent \
      "$mcFolder/panels.ini" \
      ${./panels.ini}
    assertFileContent \
      "$mcFolder/filehighlight.ini"  \
      ${./filehighlight.ini}
  '';
}
