{
  wayland.windowManager.labwc = {
    enable = true;
    package = null;
    menu = [
      {
        menuId = "client-menu";
        label = "Client Menu";
        icon = "";
        items = [
          {
            label = "Maximize";
            icon = "";
            action = {
              name = "ToggleMaximize";
            };
          }
          {
            label = "Fullscreen";
            action = {
              name = "ToggleFullscreen";
            };
          }
          {
            label = "Always on Top";
            action = {
              name = "ToggleAlwaysOnTop";
            };
          }
          {
            label = "Alacritty";
            action = {
              name = "Execute";
              command = "alacritty";
            };
          }
          {
            separator = { };
          }
          {
            label = "Workspace";
            menuId = "workspace";
            icon = "";
            items = [
              {
                label = "Move Left";
                action = {
                  name = "SendToDesktop";
                  to = "left";
                };
              }
            ];
          }
          {
            separator = {
              label = "sep";
            };
          }
        ];
      }
      {
        menuId = "menu-two";
        label = "Client Menu Two";
        icon = "";
        items = [
          {
            label = "Menu In Menu";
            menuId = "menu-in-menu";
            icon = "";
            items = [
              {
                label = "Menu In Menu In Menu";
                menuId = "menu-in-menu-in-menu";
                icon = "";
                items = [
                  {
                    label = "Move Right";
                    action = {
                      name = "SendToDesktop";
                      to = "right";
                    };
                  }
                ];
              }
            ];
          }
        ];
      }
      { menuId = ""; }
    ];
  };

  nmt.script = ''
    labwcMenuConfig=home-files/.config/labwc/menu.xml

    assertFileExists "$labwcMenuConfig"
    assertFileContent "$labwcMenuConfig" "${./menu.xml}"
  '';
}
