{ lib, options, ... }:
{
  services.mako = {
    enable = true;
    # Using old option names that should be renamed to settings.kebab-case
    actions = true;
    anchor = "top-right";
    backgroundColor = "#000000";
    borderColor = "#FFFFFF";
    borderRadius = 0;
    borderSize = 2;
    defaultTimeout = 5000;
    font = "monospace 10";
    format = "<b>%s</b>\n%b";
    groupBy = "app-name";
    height = 100;
    iconPath = "/usr/share/icons/hicolor";
    icons = true;
    ignoreTimeout = false;
    layer = "top";
    margin = 10;
    markup = true;
    maxHistory = 5;
    maxIconSize = 32;
    maxVisible = 3;
    output = "HDMI-A-1";
    padding = "5,10";
    progressColor = "#4C7899";
    sort = "-time";
    textColor = "#FFFFFF";
    width = 300;
  };

  test.asserts.warnings.expected =
    let
      renamedOptions = [
        "groupBy"
        "ignoreTimeout"
        "defaultTimeout"
        "format"
        "actions"
        "markup"
        "iconPath"
        "maxIconSize"
        "icons"
        "progressColor"
        "borderRadius"
        "borderColor"
        "borderSize"
        "padding"
        "margin"
        "height"
        "width"
        "textColor"
        "backgroundColor"
        "font"
        "anchor"
        "layer"
        "output"
        "sort"
        "maxHistory"
        "maxVisible"
      ];
    in
    map (
      option:
      ''The option `services.mako.${option}' defined in ${
        lib.showFiles options.services.mako.${option}.files
      } has been renamed to `services.mako.settings.${lib.hm.strings.toKebabCase option}'.''
    ) renamedOptions;

  nmt.script = ''
    assertFileExists home-files/.config/mako/config
    assertFileContent home-files/.config/mako/config \
    ${./renamed-options-config}
  '';
}
