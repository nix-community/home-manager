{
  services.mako = {
    enable = true;
    settings = {
      actions = "true";
      anchor = "top-right";
      backgroundColor = "#000000";
      borderColor = "#FFFFFF";
      borderRadius = "0";
      defaultTimeout = "0";
      font = "monospace 10";
      height = "100";
      width = "300";
      icons = "true";
      ignoreTimeout = "false";
      layer = "top";
      margin = "10";
      markup = "true";
    };
    extraConfig = ''
      [mode=do-not-disturb]
      invisible=1

      [app-name="Google Chrome"]
      max-visible=1
      history=0
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/mako/config
    assertFileContent home-files/.config/mako/config \
    ${./config}
  '';
}
