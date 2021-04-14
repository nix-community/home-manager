{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.htop.enable = true;
    programs.htop.settings = {
      color_scheme = 6;
      cpu_count_from_one = 0;
      delay = 15;
      fields = with config.lib.htop.fields; [
        PID
        USER
        PRIORITY
        NICE
        M_SIZE
        M_RESIDENT
        M_SHARE
        STATE
        PERCENT_CPU
        PERCENT_MEM
        TIME
        COMM
      ];
      highlight_base_name = 1;
      highlight_megabytes = 1;
      highlight_threads = 1;
    } // (with config.lib.htop;
      leftMeters {
        AllCPUs2 = modes.Bar;
        Memory = modes.Bar;
        Swap = modes.Bar;
        Zram = modes.Text;
      }) // (with config.lib.htop;
        rightMeters {
          Tasks = modes.Text;
          LoadAverage = modes.Text;
          Uptime = modes.Text;
          Systemd = modes.Text;
        });

    nmt.script = ''
      assertFileExists home-files/.config/htop/htoprc
    '';
  };
}
