{ pkgs, ... }:
let
  layout_xml = builtins.readFile ./item_dmenu.xml;
in
{
  services.walker = {
    enable = true;
    systemd.enable = true;
    settings = {
      app_launch_prefix = "";
      terminal_title_flag = "";
      locale = "";
      close_when_open = false;
      monitor = "";
      hotreload_theme = false;
      as_window = false;
      timeout = 0;
      disable_click_to_close = false;
      force_keyboard_focus = false;
    };

    theme = {
      name = "mytheme";
      style = ''
        * {
          color: #dcd7ba;
        }
      '';
      # create 2 identical files, one points into the store the other is a direct text
      layout.item_dmenu_two = pkgs.writeText "item_dmenu.xml" layout_xml;
      layout.item_dmenu_one = layout_xml;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/walker/config.toml
    assertFileExists home-files/.config/walker/themes/mytheme/style.css
    assertFileExists home-files/.config/walker/themes/mytheme/item_dmenu_one.xml
    assertFileExists home-files/.config/walker/themes/mytheme/item_dmenu_two.xml

    assertFileContent home-files/.config/walker/themes/mytheme/item_dmenu_one.xml \
    ${./item_dmenu.xml}

    assertFileContent home-files/.config/walker/themes/mytheme/item_dmenu_two.xml \
    ${./item_dmenu.xml}

    assertFileContent home-files/.config/walker/config.toml \
    ${./config.toml}

    assertFileContent home-files/.config/walker/themes/mytheme/style.css \
    ${./mytheme.css}
  '';
}
