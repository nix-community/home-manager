{ config, ... }:

# When not specified in `programs.k9s.settings.ui.skin`,
# test that the first skin name (alphabetically) is used in the config file

{
  programs.k9s = {
    enable = true;
    settings = {
      k9s = {
        refreshRate = 2;
        maxConnRetry = 5;
        enableMouse = true;
        headless = false;
      };
    };
    skins = {
      "default" = {
        k9s = {
          body = {
            fgColor = "dodgerblue";
            bgColor = "#ffffff";
            logoColor = "#0000ff";
          };
          info = {
            fgColor = "lightskyblue";
            sectionColor = "steelblue";
          };
        };
      };
      "alt-skin" = {
        k9s = {
          body = {
            fgColor = "orangered";
            bgColor = "#ffffff";
            logoColor = "#0000ff";
          };
          info = {
            fgColor = "red";
            sectionColor = "mediumvioletred";
          };
        };
      };
    };
  };

  test.stubs.k9s = { };

  nmt.script = ''
    assertFileExists home-files/.config/k9s/config.yaml
    assertFileContent \
      home-files/.config/k9s/config.yaml \
      ${./partial-skin-settings-expected.yaml}
  '';
}
