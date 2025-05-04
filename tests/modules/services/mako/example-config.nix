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

    criteria = {
      "actionable=true" = {
        anchor = "top-left";
      };

      "app-name=Google\\ Chrome" = {
        max-visible = "5";
      };

      "field1=value field2=value" = {
        text-alignment = "left";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/mako/config
    assertFileContent home-files/.config/mako/config \
    ${./config}
  '';
}
