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
      layout.item_dmenu = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <interface>
          <requires lib="gtk" version="4.0"></requires>
          <object class="GtkBox" id="ItemBox">
            <style>
              <class name="item-box"></class>
            </style>
            <property name="orientation">horizontal</property>
            <property name="spacing">10</property>
            <child>
              <object class="GtkBox" id="ItemTextBox">
                <style>
                  <class name="item-text-box"></class>
                </style>
                <property name="orientation">vertical</property>
                <property name="hexpand">true</property>
                <property name="vexpand">true</property>
                <property name="vexpand-set">true</property>
                <property name="spacing">0</property>
                <child>
                  <object class="GtkLabel" id="ItemText">
                    <style>
                      <class name="item-text"></class>
                    </style>
                    <property name="vexpand">true</property>
                    <property name="xalign">0</property>
                    <property name="lines">1</property>
                    <property name="ellipsize">3</property>
                    <property name="single-line-mode">true</property>
                  </object>
                </child>
              </object>
            </child>
            <child>
              <object class="GtkLabel" id="QuickActivation">
                <style>
                  <class name="item-quick-activation"></class>
                </style>
                <property name="wrap">false</property>
                <property name="valign">center</property>
                <property name="xalign">0</property>
                <property name="yalign">0.5</property>
              </object>
            </child>
          </object>
        </interface>
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/walker/config.toml
    assertFileExists home-files/.config/walker/themes/mytheme/style.css
    assertFileExists home-files/.config/walker/themes/mytheme/item_dmenu.xml

    assertFileContent home-files/.config/walker/config.toml \
    ${./config.toml}

    assertFileContent home-files/.config/walker/themes/mytheme/style.css \
    ${./mytheme.css}
  '';
}
