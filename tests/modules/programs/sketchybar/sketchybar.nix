{ config, ... }:

{
  programs.sketchybar = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "sketchybar";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/sketchybar
        chmod 755 $out/bin/sketchybar
      '';
    };

    configType = "bash";

    config = ''
      # Define colors
      export COLOR_BLACK="0xff181926"
      export COLOR_WHITE="0xffcad3f5"

      # Configure bar
      sketchybar --bar height=32 \
                      position=top \
                      padding_left=10 \
                      padding_right=10 \
                      color=$COLOR_BLACK

      # Configure default values
      sketchybar --default icon.font="SF Pro:Bold:14.0" \
                          icon.color=$COLOR_WHITE \
                          label.font="SF Pro:Bold:14.0" \
                          label.color=$COLOR_WHITE

      # Add items to the bar
      sketchybar --add item clock right \
                --set clock script="date '+%H:%M'" \
                            update_freq=10

      # Update the bar
      sketchybar --update
    '';
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/sketchybar/sketchybarrc \
      ${./sketchybarrc.bash}
  '';
}
