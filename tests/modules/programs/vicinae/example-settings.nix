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
      base16-default-dark = {
        version = "1.0.0";
        appearance = "dark";
        name = "base16 default dark";
        description = "base16 default dark by Chris Kempson";
        palette = {
          background = "#181818";
          foreground = "#d8d8d8";
          blue = "#7cafc2";
          green = "#a3be8c";
          magenta = "#ba8baf";
          orange = "#dc9656";
          purple = "#a16946";
          red = "#ab4642";
          yellow = "#f7ca88";
          cyan = "#86c1b9";
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
    assertFileExists      "home-files/.config/vicinae/vicinae.json"
    assertFileExists      "home-files/.config/systemd/user/vicinae.service"
    assertFileExists      "home-files/.local/share/vicinae/extensions/gif-search/package.json"
    assertFileExists      "home-files/.local/share/vicinae/extensions/test-extension/package.json"
  '';
}
