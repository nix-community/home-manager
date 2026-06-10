{ pkgs, ... }:
{
  # make sure theme directory is created from package, and setting is set
  config = {
    programs.pegasus-frontend = {
      enable = true;
      theme = {
        name = "my_theme";
        package = pkgs.runCommand "theme-test" { } "mkdir -p $out/theme_test_directory";
        settings = {
          key = "value";
        };
      };
      # also test extraConfig for settings
      settings.extraConfig.extra_config_value.item = "test";
    };

    nmt.script = ''
      cfg=home-files/.config/pegasus-frontend

      assertFileExists $cfg/settings.txt
      assertFileContent $cfg/settings.txt ${./theme-settings.txt}

      assertFileExists $cfg/theme_settings/my_theme.json
      assertFileContent $cfg/theme_settings/my_theme.json ${builtins.toFile "settings.json" ''{"key":"value"}''}

      assertDirectoryExists $cfg/themes/my_theme/theme_test_directory
    '';
  };
}
