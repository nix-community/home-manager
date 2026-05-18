{
  programs.wlr-which-key = {
    enable = true;
    settings = {
      font = "JetBrainsMono Nerd Font 12";
      background = "#282828d0";
      anchor = "center"; # this will be overridden
    };
    extraMenus = {
      apps = {
        inheritSettings = true;
        settings = {
          anchor = "bottom-left"; # overrides top-level anchor
          menu = [
            {
              key = "f";
              desc = "Firefox";
              cmd = "firefox";
            }
          ];
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/wlr-which-key/apps.yaml
    assertFileContent home-files/.config/wlr-which-key/apps.yaml \
      ${./expected-apps.yaml}
  '';
}
