{ pkgs, config, ... }: rec {
  config = {
    xsession.windowManager.leftwm = {
      enable = true;
      settings = { modkey = "Mod4"; };
      themes = {
        current = config.xsession.windowManager.leftwm.themes.test;
        test = {
          up = ''
            #!/usr/bin/env bash

            leftwm command "LoadTheme 
            $HOME/.config/leftwm/themes/current/theme.toml"
          '';
          down = pkgs.writeText "down" ''
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
        test-package = let
          up = builtins.readFile ./theme-up;
          down = builtins.readFile ./theme-down;
          theme = builtins.readFile ./theme-theme.toml;
        in pkgs.runCommand "test-package" { } ''
          mkdir $out
          touch $out/up $out/down $out/theme.toml
          chmod +x $out/up $out/down
        '';
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
      test_package=home-files/.config/leftwm/themes/test-package
      test_package_up=$test_package/up
      test_package_down=$test_package/down
      test_package_theme=$test_package/theme.toml

      assertFileExists "$test_up"
      assertFileExists "$test_down"
      assertFileExists "$test_theme"
      assertFileIsExecutable "$test_up"
      assertFileIsExecutable "$test_down"
      assertFileContent "$test_up" ${./theme-up}
      assertFileContent "$test_down" ${./theme-down}
      assertFileContent "$test_theme" ${./theme-theme.toml}

      assertFileExists "$current_up"
      assertFileExists "$current_down"
      assertFileExists "$current_theme"
      assertFileIsExecutable "$test_up"
      assertFileIsExecutable "$test_down"
      assertFileContent "$current_up" ${./theme-up}
      assertFileContent "$current_down" ${./theme-down}
      assertFileContent "$current_theme" ${./theme-theme.toml}

      assertFileExists "$test_package_up"
      assertFileExists "$test_package_down"
      assertFileExists "$test_package_theme"
      assertFileIsExecutable "$test_package_up"
      assertFileIsExecutable "$test_package_down"
      assertFileContent "$test_package_up" ${builtins.toFile "up" ""}
      assertFileContent "$test_package_down" ${builtins.toFile "down" ""}
      assertFileContent "$test_package_theme" ${builtins.toFile "theme" ""}
    '';
  };
}
