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

    extraConfig = ''
      [urgency=low]
      border-color=#CCCCCC

      [urgency=normal]
      border-color=#FFF700

      [urgency=high]
      border-color=#FF0000
      default-timeout=0

      [app-name=system-notify]
      border-color=#FF0000
      default-timeout=0

      [summary~="Update"]
      border-color=#0000FF
      default-timeout=20000

      [body~="Update"]
      border-color=#0000FF
      default-timeout=20000

      [summary~=failed]
      border-color=#FF0000
      default-timeout=0

      [summary~=error]
      border-color=#FF0000
      default-timeout=0

      [body~=failed]
      border-color=#FF0000
      default-timeout=0

      [body~=error]
      border-color=#FF0000
      default-timeout=0
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/mako/config
    assertFileContent home-files/.config/mako/config \
    ${./config}
  '';
}
