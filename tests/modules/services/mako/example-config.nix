{
  services.mako = {
    enable = true;
    settings = {
      actions = true;
      anchor = "top-right";
      background-color = "#000000";
      border-color = "#FFFFFF";
      border-radius = 0;
      default-timeout = 0;
      font = "monospace 10";
      height = 100;
      width = 300;
      icons = true;
      ignore-timeout = false;
      layer = "top";
      margin = 10;
      markup = true;

      "actionable=true" = {
        anchor = "top-left";
      };
      "app-name=Google\\ Chrome" = {
        max-visible = 5;
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
