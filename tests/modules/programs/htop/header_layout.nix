{ config, lib, pkgs, ... }:

with lib;

{
  config = with config.lib.htop; {
    programs.htop.enable = true;
    programs.htop.settings = {
      header_layout = "two_50_50";
      column_meters_0 = [ "AllCPUs2" "Memory" "Swap" "Zram" ];
      column_meters_modes_0 = [ modes.Bar modes.Bar modes.Bar modes.Text ];
      column_meters_1 = [ "Tasks" "LoadAverage" "Uptime" "Systemd" ];
      column_meters_modes_1 = [ modes.Text modes.Text modes.Text modes.Text ];
    };

    test.stubs.htop = { };

    # Test that the 'fields' key is written in addition to the customized
    # settings or htop won't read the options.
    nmt.script = ''
      htoprc=home-files/.config/htop/htoprc
      assertFileExists $htoprc
      assertFileContent $htoprc \
        ${
          builtins.toFile "htoprc-expected" ''
            header_layout=two_50_50
            column_meters_0=AllCPUs2 Memory Swap Zram
            column_meters_1=Tasks LoadAverage Uptime Systemd
            column_meters_modes_0=1 1 1 2
            column_meters_modes_1=2 2 2 2
            fields=0 48 17 18 38 39 40 2 46 47 49 1
          ''
        }
    '';
  };

}
