{ config, lib, ... }:

{
  programs.mc = {
    enable = true;

    settings = {
      "Midnight-Commander" = {
        skin = "nicedark";
        show_hidden = true;
        auto_save_setup = true;
      };
    };

    keymapSettings = {
      panel = {
        Enter = "Select";
      };
    };
  };

  nmt.script = ''

    mcFolder="home-files/.config/mc"

    assertFileExists "$mcFolder/ini"
    assertFileExists "$mcFolder/mc.keymap"

    assertFileContains "$mcFolder/ini" "[Midnight-Commander]
    skin=nicedark
    show_hidden=true
    auto_save_setup=true"

    assertFileContains "$mcFolder/mc.keymap" "[panel]
    Enter=Select"

  '';
}
