{
  programs.sketchybar = {
    enable = true;
    plugins = {
      disk = ./plugins/disk.sh;
      network = ./plugins/network.sh;
      ram = ''
        sketchybar -m --set "$NAME" label="$(memory_pressure | grep "System-wide memory free percentage:" | awk '{ printf("%02.0f\n", 100-$5"%") }')%"
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/sketchybar/plugins/disk.sh
    assertFileExists home-files/.config/sketchybar/plugins/network.sh
    assertFileExists home-files/.config/sketchybar/plugins/ram.sh

    assertFileContent home-files/.config/sketchybar/plugins/disk.sh \
    ${./plugins/disk.sh}
    assertFileExists home-files/.config/sketchybar/plugins/network.sh \
    ${./plugins/network.sh}
    assertFileExists home-files/.config/sketchybar/plugins/ram.sh \
    ${./plugins/ram.sh}
  '';
}
