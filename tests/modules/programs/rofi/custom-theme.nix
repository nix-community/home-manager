{ config, lib, ... }:

{
  programs.rofi = {
    enable = true;
    font = lib.mkOverride 1501 "ignored";
    terminal = lib.mkOverride 1501 "/ignored";
    cycle = lib.mkOverride 1501 true;
    location = lib.mkOverride 1501 "bottom";
    modes = lib.mkOverride 1501 [ "ignored" ];
    xoffset = lib.mkOverride 1501 9;
    yoffset = lib.mkOverride 1501 9;
    extraConfig = lib.mkOverride 1501 {
      font = lib.mkForce "ignored-overlay";
      xoffset = lib.mkForce 9;
    };

    theme =
      let
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        "@import" = "~/.cache/wal/colors-rofi-dark";

        "*" = {
          background-color = mkLiteral "#000000";
          foreground-color = mkLiteral "rgba ( 250, 251, 252, 100 % )";
          border-color = mkLiteral "#FFFFFF";
          width = 512;
        };

        "#inputbar" = {
          children = map mkLiteral [
            "prompt"
            "entry"
          ];
        };

        "#textbox-prompt-colon" = {
          expand = false;
          str = ":";
          margin = mkLiteral "0px 0.3em 0em 0em";
          text-color = mkLiteral "@foreground-color";
        };
      };
  };

  assertions = [
    {
      assertion =
        config.programs.rofi.font == null
        && config.programs.rofi.terminal == null
        && config.programs.rofi.cycle == null
        && config.programs.rofi.location == "center"
        && config.programs.rofi.modes == [ ]
        && config.programs.rofi.xoffset == 0
        && config.programs.rofi.yoffset == 0;
      message = "Legacy sources below option-default priority must retain historical defaults.";
    }
  ];

  nmt.script = ''
    assertFileContent \
      home-files/.config/rofi/config.rasi \
      ${./custom-theme-config.rasi}
    assertFileContent \
      home-files/.local/share/rofi/themes/custom.rasi \
      ${./custom-theme.rasi}
  '';
}
