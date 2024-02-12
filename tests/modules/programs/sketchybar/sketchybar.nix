{ config, ... }:

{
  programs.sketchybar = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    configType = "bash";

    variables = {
      PADDING = "3";
      FONT = "SF Pro";
      COLOR = "0xff0000ff";
    };

    config = {
      bar = {
        height = 30;
        position = "top";
        padding_left = 10;
        padding_right = 10;
      };

      defaults = {
        "icon.font" = "$FONT";
        "icon.color" = "$COLOR";
        "background.height" = 24;
      };
    };

    plugins = [
      {
        name = "clock";
        placement = "right";
        script = "./scripts/clock.sh";
        update_freq = 1;
      }
    ];

    extraConfig = ''
      # This is a test configuration
      sketchybar --add item cpu right \
                --set cpu script="$PLUGIN_DIR/cpu.sh" \
                --subscribe cpu system_woke
    '';
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/sketchybar/sketchybarrc \
      ${./sketchybarrc.bash}
  '';
}
