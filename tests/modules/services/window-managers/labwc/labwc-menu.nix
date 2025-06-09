{
  wayland.windowManager.labwc = {
    enable = true;
    package = null;
    menu = [
      {
        label = "pipemenu";
        menuId = "menu";
        execute = "/home/user/nix/scripts/pipe.sh";
      }
      {
        menuId = "client-menu";
        label = "Client Menu";
        icon = "path";
        items = [
          {
            label = "Maximize";
            icon = "Max";
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
        icon = "menu-two";
        items = [
          {
            label = "Menu In Menu";
            menuId = "menu-in-menu";
            items = [
              {
                label = "Menu In Menu In Menu";
                menuId = "menu-in-menu-in-menu";
                icon = "menu-in-menu-in-menu";
                items = [
                  {
                    label = "Move Right";
                    action = {
                      name = "SendToDesktop";
                      to = "right";
                    };
                  }
                  { menuId = "fourth"; }
                ];
              }
            ];
          }
        ];
      }
      #  <!-- A submenu defined elsewhere, uses external label and icon attributes -->
      { menuId = ""; }
    ];
  };

  nmt.script = ''
    labwcMenuConfig=home-files/.config/labwc/menu.xml

    assertFileExists "$labwcMenuConfig"
    assertFileContent "$labwcMenuConfig" "${./menu.xml}"
  '';
}
