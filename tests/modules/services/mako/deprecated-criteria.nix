{
  services.mako = {
    enable = true;
    # Global settings
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
    };

    # Using deprecated criteria option
    criteria = {
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

  test.asserts.warnings.expected = [
    ''
      The option `services.mako.criteria` is deprecated and will be removed in a future release.
      Please use `services.mako.settings` with nested attributes instead.

      For example, instead of:
        criteria = {
          "actionable=true" = {
            anchor = "top-left";
          };
        };

      Use:
        settings = {
          # Global settings here...

          # Criteria sections
          "actionable=true" = {
            anchor = "top-left";
          };
        };
    ''
  ];

  nmt.script = ''
    assertFileExists home-files/.config/mako/config
    assertFileContent home-files/.config/mako/config \
    ${./config}
  '';
}
