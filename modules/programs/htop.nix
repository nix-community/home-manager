{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.htop;

  list = xs: concatMapStrings (x: "${toString x} ") xs;

  bool = b: if b then "1" else "0";

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

  # Mapping from names to defaults
  meters = {
    Clock = 2;
    LoadAverage = 2;
    Load = 2;
    Memory = 1;
    Swap = 1;
    Tasks = 2;
    Uptime = 2;
    Battery = 2;
    Hostname = 2;
    AllCPUs = 1;
    AllCPUs2 = 1;
    AllCPUs4 = 1;
    LeftCPUs = 1;
    RightCPUs = 1;
    Right = 1;
    CPUs = 1;
    LeftCPUs2 = 1;
    RightCPUs2 = 1;
    LeftCPUs4 = 1;
    RightCPUs4 = 1;
    Blank = 2;
    PressureStallCPUSome = 2;
    PressureStallIOSome = 2;
    PressureStallIOFull = 2;
    PressureStallMemorySome = 2;
    PressureStallMemoryFull = 2;
    ZFSARC = 2;
    ZFSCARC = 2;
    CPU = 1;
    "CPU(1)" = 1;
    "CPU(2)" = 1;
    "CPU(3)" = 1;
    "CPU(4)" = 1;
    "CPU(5)" = 1;
    "CPU(6)" = 1;
    "CPU(7)" = 1;
    "CPU(8)" = 1;
  };

  singleMeterType = let
    meterEnum = types.enum (attrNames meters);
    meterSubmodule = types.submodule {
      options = {
        kind = mkOption {
          type = types.enum (attrNames meters);
          example = "AllCPUs";
          description = "What kind of meter.";
        };

        mode = mkOption {
          type = types.enum [ 1 2 3 4 ];
          example = 2;
          description =
            "Which mode the meter should use, one of 1(Bar) 2(Text) 3(Graph) 4(LED).";
        };
      };
    };
  in types.coercedTo meterEnum (m: {
    kind = m;
    mode = meters.${m};
  }) meterSubmodule;

  meterType = types.submodule {
    options = {
      left = mkOption {
        description = "Meters shown in the left header.";
        default = [ "AllCPUs" "Memory" "Swap" ];
        example = [
          "Memory"
          "LeftCPUs2"
          "RightCPUs2"
          {
            kind = "CPU";
            mode = 3;
          }
        ];
        type = types.listOf singleMeterType;
      };
      right = mkOption {
        description = "Meters shown in the right header.";
        default = [ "Tasks" "LoadAverage" "Uptime" ];
        example = [
          {
            kind = "Clock";
            mode = 4;
          }
          "Uptime"
          "Tasks"
        ];
        type = types.listOf singleMeterType;
      };
    };
  };

in {
  options.programs.htop = {
    enable = mkEnableOption "htop";

    fields = mkOption {
      type = types.listOf (types.enum (attrNames fields));
      default = [
        "PID"
        "USER"
        "PRIORITY"
        "NICE"
        "M_SIZE"
        "M_RESIDENT"
        "M_SHARE"
        "STATE"
        "PERCENT_CPU"
        "PERCENT_MEM"
        "TIME"
        "COMM"
      ];
      example = [
        "PID"
        "USER"
        "PRIORITY"
        "PERCENT_CPU"
        "M_RESIDENT"
        "PERCENT_MEM"
        "TIME"
        "COMM"
      ];
      description = "Active fields shown in the table.";
    };

    sortKey = mkOption {
      type = types.enum (attrNames fields);
      default = "PERCENT_CPU";
      example = "TIME";
      description = "Which field to use for sorting.";
    };

    sortDescending = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to sort descending or not.";
    };

    hideThreads = mkOption {
      type = types.bool;
      default = false;
      description = "Hide threads.";
    };

    hideKernelThreads = mkOption {
      type = types.bool;
      default = true;
      description = "Hide kernel threads.";
    };

    hideUserlandThreads = mkOption {
      type = types.bool;
      default = false;
      description = "Hide userland process threads.";
    };

    shadowOtherUsers = mkOption {
      type = types.bool;
      default = false;
      description = "Shadow other users' processes.";
    };

    showThreadNames = mkOption {
      type = types.bool;
      default = false;
      description = "Show custom thread names.";
    };

    showProgramPath = mkOption {
      type = types.bool;
      default = true;
      description = "Show program path.";
    };

    highlightBaseName = mkOption {
      type = types.bool;
      default = false;
      description = "Highlight program <quote>basename</quote>.";
    };

    highlightMegabytes = mkOption {
      type = types.bool;
      default = true;
      description = "Highlight large numbers in memory counters.";
    };

    highlightThreads = mkOption {
      type = types.bool;
      default = true;
      description = "Display threads in a different color.";
    };

    treeView = mkOption {
      type = types.bool;
      default = false;
      description = "Tree view.";
    };

    headerMargin = mkOption {
      type = types.bool;
      default = true;
      description = "Leave a margin around header.";
    };

    detailedCpuTime = mkOption {
      type = types.bool;
      default = false;
      description =
        "Detailed CPU time (System/IO-Wait/Hard-IRQ/Soft-IRQ/Steal/Guest).";
    };

    cpuCountFromZero = mkOption {
      type = types.bool;
      default = false;
      description = "Count CPUs from 0 instead of 1.";
    };

    showCpuUsage = mkOption {
      type = types.bool;
      default = false;
      description = "Show CPU usage frequency.";
    };

    showCpuFrequency = mkOption {
      type = types.bool;
      default = false;
      description = "Show CPU frequency.";
    };

    updateProcessNames = mkOption {
      type = types.bool;
      default = false;
      description = "Update process names on every refresh.";
    };

    accountGuestInCpuMeter = mkOption {
      type = types.bool;
      default = false;
      description = "Add guest time in CPU meter percentage.";
    };

    colorScheme = mkOption {
      type = types.enum [ 0 1 2 3 4 5 6 ];
      default = 0;
      example = 6;
      description = "Which color scheme to use.";
    };

    enableMouse = mkOption {
      type = types.bool;
      default = true;
      description = "Enable mouse support.";
    };

    delay = mkOption {
      type = types.int;
      default = 15;
      example = 2;
      description = "Set the delay between updates, in tenths of seconds.";
    };

    meters = mkOption {
      description = "Meters shown in the header.";
      default = {
        left = [ "AllCPUs" "Memory" "Swap" ];
        right = [ "Tasks" "LoadAverage" "Uptime" ];
      };
      example = {
        left = [
          "Memory"
          "CPU"
          "LeftCPUs2"
          "RightCPUs2"
          {
            kind = "CPU";
            mode = 3;
          }
        ];
        right = [
          {
            kind = "Clock";
            mode = 4;
          }
          "Uptime"
          "Tasks"
          "LoadAverage"
          {
            kind = "Battery";
            mode = 1;
          }
        ];
      };
      type = meterType;
    };

    vimMode = mkOption {
      type = types.bool;
      default = false;
      description = "Vim key bindings.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.htop ];

    xdg.configFile."htop/htoprc".text = let
      leftMeters = map (m: m.kind) cfg.meters.left;
      leftModes = map (m: m.mode) cfg.meters.left;
      rightMeters = map (m: m.kind) cfg.meters.right;
      rightModes = map (m: m.mode) cfg.meters.right;
    in ''
      # This file is regenerated by home-manager
      # when options are changed in the config
      fields=${list (map (n: fields.${n}) cfg.fields)}
      sort_key=${toString (fields.${cfg.sortKey})}
      sort_direction=${bool cfg.sortDescending}
      hide_threads=${bool cfg.hideThreads}
      hide_kernel_threads=${bool cfg.hideKernelThreads}
      hide_userland_threads=${bool cfg.hideUserlandThreads}
      shadow_other_users=${bool cfg.shadowOtherUsers}
      show_thread_names=${bool cfg.showThreadNames}
      show_program_path=${bool cfg.showProgramPath}
      highlight_base_name=${bool cfg.highlightBaseName}
      highlight_megabytes=${bool cfg.highlightMegabytes}
      highlight_threads=${bool cfg.highlightThreads}
      tree_view=${bool cfg.treeView}
      header_margin=${bool cfg.headerMargin}
      detailed_cpu_time=${bool cfg.detailedCpuTime}
      cpu_count_from_zero=${bool cfg.cpuCountFromZero}
      show_cpu_usage=${bool cfg.showCpuUsage}
      show_cpu_frequency=${bool cfg.showCpuFrequency}
      update_process_names=${bool cfg.updateProcessNames}
      account_guest_in_cpu_meter=${bool cfg.accountGuestInCpuMeter}
      color_scheme=${toString cfg.colorScheme}
      enable_mouse=${bool cfg.enableMouse}
      delay=${toString cfg.delay}
      left_meters=${list leftMeters}
      left_meter_modes=${list leftModes}
      right_meters=${list rightMeters}
      right_meter_modes=${list rightModes}
      vim_mode=${bool cfg.vimMode}
    '';
  };
}
