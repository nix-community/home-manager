{ ... }: {
  config = {
    xsession.windowManager.leftwm = {
      enable = true;
      settings = { modkey = "Mod4"; };
      themes = {
        current = {
          up = ''
            #!/usr/bin/env bash

            leftwm command "LoadTheme 
            $HOME/.config/leftwm/themes/current/theme.toml"
          '';
          down = ''
            #!/usr/bin/env bash

            leftwm command "UnloadTheme"
          '';
          theme = {
            border_width = 10;
            margin = 5;
            default_border_color = "#37474F";
            floating_border_color = "#225588";
            focused_border_color = "#885522";
          };
        };
      };
    };

    test.stubs.leftwm = { };

    nmt.script = ''
      up=home-files/.config/leftwm/themes/current/up
      down=home-files/.config/leftwm/themes/current/down
      theme=home-files/.config/leftwm/themes/current/theme.toml

      assertFileExists "$up"
      assertFileExists "$down"
      assertFileExists "$theme"
      assertFileIsExecutable "$up"
      assertFileIsExecutable "$down"
      assertFileContent "$up" ${./theme-up}
      assertFileContent "$down" ${./theme-down}
      assertFileContent "$theme" ${./theme-theme.toml}
    '';
  };
}
