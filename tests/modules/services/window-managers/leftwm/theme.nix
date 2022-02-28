{ pkgs, config, ... }: rec {
  config = {
    xsession.windowManager.leftwm = {
      enable = true;
      settings = { modkey = "Mod4"; };
      themes = {
        current = config.xsession.windowManager.leftwm.themes.test;
        test = {
          up = pkgs.writeShellScript "up" ''
            leftwm command "LoadTheme 
            $HOME/.config/leftwm/themes/current/theme.toml"
          '';
          down = pkgs.writeShellScript "down" ''
            leftwm command "UnloadTheme"
          '';
          "theme.toml" = (pkgs.formats.toml { }).generate "theme.toml" {
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
      test=home-files/.config/leftwm/themes/test
      test_up=$test/up
      test_down=$test/down
      test_theme=$test/theme.toml
      current=home-files/.config/leftwm/themes/current
      current_up=$current/up
      current_down=$current/down
      current_theme=$current/theme.toml

      assertFileExists "$test_up"
      assertFileExists "$test_down"
      assertFileExists "$test_theme"
      assertFileIsExecutable "$test_up"
      assertFileIsExecutable "$test_down"
      assertFileContains "$test_up" 'leftwm command "LoadTheme 
          $HOME/.config/leftwm/themes/current/theme.toml"'
      assertFileContains "$test_down" 'leftwm command "UnloadTheme"'
      assertFileContent "$test_theme" ${./theme-theme.toml}

      assertFileExists "$current_up"
      assertFileExists "$current_down"
      assertFileExists "$current_theme"
      assertFileIsExecutable "$current_up"
      assertFileIsExecutable "$current_down"
      assertFileContains "$current_up" 'leftwm command "LoadTheme 
          $HOME/.config/leftwm/themes/current/theme.toml"'
      assertFileContains "$current_down" 'leftwm command "UnloadTheme"'
      assertFileContent "$current_theme" ${./theme-theme.toml}
    '';
  };
}
