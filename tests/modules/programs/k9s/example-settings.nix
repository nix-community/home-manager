{ config, ... }:

{
  programs.k9s = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      k9s = {
        refreshRate = 2;
        maxConnRetry = 5;
        enableMouse = true;
        headless = false;
      };
    };

    skin = {
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
  };

  nmt.script = ''
    assertFileExists home-files/.config/k9s/config.yml
    assertFileContent \
      home-files/.config/k9s/config.yml \
      ${./example-config-expected.yml}
    assertFileExists home-files/.config/k9s/skin.yml
    assertFileContent \
      home-files/.config/k9s/skin.yml \
      ${./example-skin-expected.yml}
  '';
}
