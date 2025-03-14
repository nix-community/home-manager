{ config, ... }:

{
  programs.lapce = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    settings = {
      core = {
        custom-titlebar = false;
        color-theme = "Custom";
        icon-theme = "Material Icons";
      };
      editor = {
        font-family = "FiraCode Nerd Bold Font, monospace";
        font-size = 22;
        tab-width = 2;
        cursor-surrounding-lines = 4;
        render-whitespace = "all";
        bracket-pair-colorization = true;
        highlight-matching-brackets = true;
      };
      ui = {
        font-size = 20;
        open-editors-visible = false;
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/lapce-stable/settings.toml \
      ${./example-settings-expected.toml}
  '';
}
