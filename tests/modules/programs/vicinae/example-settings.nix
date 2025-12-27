{
  pkgs,
  config,
  ...
}:

{
  programs.vicinae = {
    enable = true;
    systemd.enable = true;

    settings = {
      faviconService = "twenty";
      font = {
        size = 10;
      };
      popToRootOnClose = false;
      rootSearch = {
        searchFiles = false;
      };
      theme = {
        name = "vicinae-dark";
      };
      window = {
        csd = true;
        opacity = 0.95;
        rounding = 10;
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
      (config.lib.vicinae.mkRayCastExtension {
        name = "gif-search";
        sha256 = "sha256-G7il8T1L+P/2mXWJsb68n4BCbVKcrrtK8GnBNxzt73Q=";
        rev = "4d417c2dfd86a5b2bea202d4a7b48d8eb3dbaeb1";
      })
      (config.lib.vicinae.mkExtension {
        name = "test-extension";
        src =
          pkgs.fetchFromGitHub {
            owner = "schromp";
            repo = "vicinae-extensions";
            rev = "f8be5c89393a336f773d679d22faf82d59631991";
            sha256 = "sha256-zk7WIJ19ITzRFnqGSMtX35SgPGq0Z+M+f7hJRbyQugw=";
          }
          + "/test-extension";
      })
    ];
  };

  nmt.script = ''
    assertFileExists      "home-files/.config/vicinae/settings.json"
    assertFileExists      "home-files/.config/systemd/user/vicinae.service"
    assertFileExists      "home-files/.local/share/vicinae/themes/catppuccin-mocha.toml"
    assertFileExists      "home-files/.local/share/vicinae/extensions/gif-search/package.json"
    assertFileExists      "home-files/.local/share/vicinae/extensions/test-extension/package.json"
    assertFileContent     "home-files/.config/systemd/user/vicinae.service"  ${./service.service}
  '';
}
