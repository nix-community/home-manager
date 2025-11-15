{ pkgs, ... }:
{
  programs.go-freeze = {
    enable = true;

    settings.user = {
      background = "#171717";
      margin = [
        0
        0
        0
        0
      ];
      padding = [
        20
        40
        20
        20
      ];
      window = false;
      width = 0;
      height = 0;
      config = "default";
      theme = "gruvbox-dark";
      border = {
        radius = 0;
        width = 0;
        color = "#515151";
      };
      shadow = {
        blur = 0;
        x = 0;
        y = 0;
      };
      font = {
        family = "Liberation Mono";
        file = "${pkgs.liberation_ttf_v2}/share/fonts/truetype/LiberationMono-Regular.ttf";
        size = 14;
        ligatures = false;
      };
      line_height = 1.2;
      line_numbers = false;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/go-freeze/user.json

    assertFileContent home-files/.config/go-freeze/user.json \
    ${builtins.toFile "expected.config_go-freeze_user.json" ''
      {
        "background": "#171717",
        "border": {
          "color": "#515151",
          "radius": 0,
          "width": 0
        },
        "config": "default",
        "font": {
          "family": "Liberation Mono",
          "file": "${pkgs.liberation_ttf_v2}/share/fonts/truetype/LiberationMono-Regular.ttf",
          "ligatures": false,
          "size": 14
        },
        "height": 0,
        "line_height": 1.2,
        "line_numbers": false,
        "margin": [
          0,
          0,
          0,
          0
        ],
        "padding": [
          20,
          40,
          20,
          20
        ],
        "shadow": {
          "blur": 0,
          "x": 0,
          "y": 0
        },
        "theme": "gruvbox-dark",
        "width": 0,
        "window": false
      }
    ''}
  '';
}
