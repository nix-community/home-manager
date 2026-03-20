{ config, pkgs, ... }:

let
  # Create a mock directory structure for testing
  configDir = pkgs.runCommand "sketchybar-config" { } ''
        mkdir -p $out/plugins
        cat > $out/sketchybarrc <<EOF
    #!/usr/bin/env bash
    # Main configuration file
    source "$CONFIG_DIR/plugins/battery.sh"
    source "$CONFIG_DIR/plugins/clock.sh"

    sketchybar --bar height=32 position=top
    sketchybar --update
    EOF
        chmod +x $out/sketchybarrc

        cat > $out/plugins/battery.sh <<EOF
    #!/usr/bin/env bash
    sketchybar --add item battery right \\
               --set battery script="\$CONFIG_DIR/plugins/battery.sh" \\
                             update_freq=10
    EOF

        cat > $out/plugins/clock.sh <<EOF
    #!/usr/bin/env bash
    sketchybar --add item clock right \\
               --set clock script="date '+%H:%M'" \\
                           update_freq=60
    EOF
  '';
in
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

    config = {
      source = configDir;
      recursive = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/sketchybar/sketchybarrc
    assertFileExists home-files/.config/sketchybar/plugins/battery.sh
    assertFileExists home-files/.config/sketchybar/plugins/clock.sh

    # Verify the main config file is executable
    [[ -x home-files/.config/sketchybar/sketchybarrc ]] || \
      echo "sketchybarrc should be executable"
  '';
}
