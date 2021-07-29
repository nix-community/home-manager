{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.htop;

  formatOption = n: v:
    let v' = if isBool v then (if v then "1" else "0") else toString v;
    in "${n}=${v'}";

  formatMeters = side: meters: {
    "${side}_meters" = concatMap (mapAttrsToList (x: _: x)) meters;
    "${side}_meter_modes" = concatMap (mapAttrsToList (_: y: y)) meters;
  };
  leftMeters = formatMeters "left";
  rightMeters = formatMeters "right";

  fields = {
    PID = 0;
    COMM = 1;
    STATE = 2;
    PPID = 3;
    PGRP = 4;
    SESSION = 5;
    TTY_NR = 6;
    TPGID = 7;
    MINFLT = 9;
    MAJFLT = 11;
    PRIORITY = 17;
    NICE = 18;
    STARTTIME = 20;
    PROCESSOR = 37;
    M_SIZE = 38;
    M_RESIDENT = 39;
    ST_UID = 45;
    PERCENT_CPU = 46;
    PERCENT_MEM = 47;
    USER = 48;
    TIME = 49;
    NLWP = 50;
    TGID = 51;
    CMINFLT = 10;
    CMAJFLT = 12;
    UTIME = 13;
    STIME = 14;
    CUTIME = 15;
    CSTIME = 16;
    M_SHARE = 40;
    M_TRS = 41;
    M_DRS = 42;
    M_LRS = 43;
    M_DT = 44;
    CTID = 99;
    VPID = 100;
    VXID = 102;
    RCHAR = 102;
    WCHAR = 103;
    SYSCR = 104;
    SYSCW = 105;
    RBYTES = 106;
    WBYTES = 107;
    CNCLWB = 108;
    IO_READ_RATE = 109;
    IO_WRITE_RATE = 110;
    IO_RATE = 111;
    CGROUP = 112;
    OOM = 113;
    IO_PRIORITY = 114;
    M_PSS = 118;
    M_SWAP = 119;
    M_PSSWP = 120;
  };

  modes = {
    Bar = 1;
    Text = 2;
    Graph = 3;
    LED = 4;
  };

  # Utilities for constructing meters
  meter = mode: name: { ${name} = mode; };
  bar = meter modes.Bar;
  text = meter modes.Text;
  graph = meter modes.Graph;
  led = meter modes.LED;
  blank = text "Blank";

in {
  options.programs.htop = {
    enable = mkEnableOption "htop";

    settings = mkOption {
      type = types.attrs;
      default = {
        account_guest_in_cpu_meter = false;
        color_scheme = 0;
        cpu_count_from_zero = false;
        delay = 15;
        detailed_cpu_time = false;
        enable_mouse = true;
        fields = with fields; [
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
        header_margin = true;
        hide_kernel_threads = true;
        hide_threads = false;
        hide_userland_threads = false;
        highlight_base_name = false;
        highlight_megabytes = true;
        highlight_threads = true;
        shadow_other_users = false;
        show_cpu_frequency = false;
        show_cpu_usage = false;
        show_program_path = true;
        show_thread_names = false;
        sort_direction = 1;
        sort_key = fields.PERCENT_CPU;
        tree_view = false;
        update_process_names = false;
        vim_mode = false;
      } // (leftMeters [
        (bar "AllCPUs2")
        (bar "Memory")
        (bar "Swap")
        (text "Zram")
      ]) // (rightMeters [
        (text "Tasks")
        (text "LoadAverage")
        (text "Uptime")
        (text "Systemd")
      ]);
      example = literalExample ''
        {
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
        } // (with config.lib.htop; leftMeters [
          (bar "AllCPUs2")
          (bar "Memory")
          (bar "Swap")
          (text "Zram")
        ]) // (with config.lib.htop; rightMeters [
          (text "Tasks")
          (text "LoadAverage")
          (text "Uptime")
          (text "Systemd")
        ]);
      '';
      description = ''
        Configuration options to add to
        <filename>~/.config/htop/htoprc</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    lib.htop = {
      inherit fields modes leftMeters rightMeters bar text graph led blank;
    };

    home.packages = [ pkgs.htop ];

    xdg.configFile."htop/htoprc".text =
      concatStringsSep "\n" (mapAttrsToList formatOption cfg.settings);
  };
}
