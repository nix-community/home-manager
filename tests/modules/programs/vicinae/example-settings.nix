{
  config,
  pkgs,
  ...
}:

let
  mkExtensionStub =
    name:
    pkgs.runCommandLocal name { } ''
      mkdir -p $out
      echo '{}' > $out/package.json
    '';
in
{
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
    package = config.lib.test.mkStubPackage {
      name = "vicinae";
      version = "0.17.0";
    };
    settings = {
      favicon_service = "twenty";
      font.normal.size = 10;
      launcher_window.layer_shell.enabled = false;
      pop_to_root_on_close = false;
      search_files_in_root = false;
      theme = {
        dark.name = "vicinae-dark";
        light.name = "vicinae-light";
      };
    };
    themes = {
      catppuccin-mocha = {
        meta = {
          version = 1;
          name = "Catppuccin Mocha";
          description = "Cozy feeling with color-rich accents";
          variant = "dark";
          icon = "icons/catppuccin-mocha.png";
          inherits = "vicinae-dark";
        };

        colors = {
          core = {
            background = "#1E1E2E";
            foreground = "#CDD6F4";
            secondary_background = "#181825";
            border = "#313244";
            accent = "#89B4FA";
          };
          accents = {
            blue = "#89B4FA";
            green = "#A6E3A1";
            magenta = "#F5C2E7";
            orange = "#FAB387";
            purple = "#CBA6F7";
            red = "#F38BA8";
            yellow = "#F9E2AF";
            cyan = "#94E2D5";
          };
        };
      };
    };

    extensions = [
      (mkExtensionStub "cdnjs")
      (mkExtensionStub "test-extension")
    ];
  };

  nmt.script = ''
    assertFileContent "home-files/.config/vicinae/settings.json" ${./settings.json}
    assertPathNotExists "home-files/.config/vicinae/vicinae.json"
    assertFileExists      "home-files/.config/systemd/user/vicinae.service"
    assertFileExists      "home-files/.local/share/vicinae/themes/catppuccin-mocha.toml"
    assertFileExists      "home-files/.local/share/vicinae/extensions/cdnjs/package.json"
    assertFileExists      "home-files/.local/share/vicinae/extensions/test-extension/package.json"

    serviceFile=$(normalizeStorePaths "home-files/.config/systemd/user/vicinae.service")
    assertFileContent  $serviceFile  ${./service.service}
  '';
}
