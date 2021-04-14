{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.htop;

  formatOption = n: v:
    let v' = if isBool v then (if v then "1" else "0") else toString v;
    in "${n}=${v'}";

  formatMeters = side: meters: {
    "${side}_meters" = mapAttrsToList (x: _: x) meters;
    "${side}_meter_modes" = mapAttrsToList (_: y: y) meters;
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

  # Mapping from names to defaults
  meters = {
    Clock = 2;
    Date = 2;
    DateTime = 2;
    LoadAverage = 2;
    Load = 2;
    Memory = 1;
    Swap = 1;
    Zram = 2;
    HugePages = 2;
    Tasks = 2;
    Uptime = 2;
    Battery = 2;
    Hostname = 2;
    AllCPUs = 1;
    AllCPUs2 = 1;
    AllCPUs4 = 1;
    AllCPUs8 = 1;
    LeftCPUs = 1;
    RightCPUs = 1;
    Right = 1;
    CPUs = 1;
    LeftCPUs2 = 1;
    RightCPUs2 = 1;
    LeftCPUs4 = 1;
    RightCPUs4 = 1;
    LeftCPUs8 = 1;
    RightCPUs8 = 1;
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
    SELinux = 2;
    Systemd = 2;
    DiskIO = 2;
    NetworkIO = 2;
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

    settings = mkOption {
      type = types.attrs;
      default = { };
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
        } // (with config.lib.htop; leftMeters {
          AllCPUs2 = modes.Bar;
          Memory = modes.Bar;
          Swap = modes.Bar;
          Zram = modes.Text;
        }) // (with config.lib.htop; rightMeters {
          Tasks = modes.Text;
          LoadAverage = modes.Text;
          Uptime = modes.Text;
          Systemd = modes.Text;
        })
      '';
      description = ''
        Configuration options to add to
        <filename>~/.config/htop/htoprc</filename>.

        This superseedes any other (deprecated) settings in this module.
      '';
    };

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
      description = ''
        Deprecated. Please use programs.htop.settings.fields instead.

        Active fields shown in the table.
      '';
    };

    sortKey = mkOption {
      type = types.enum (attrNames fields);
      default = "PERCENT_CPU";
      example = "TIME";
      description = ''
        Deprecated. Please use programs.htop.settings.sort_key instead.

        Which field to use for sorting.
      '';
    };

    sortDescending = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Deprecated. Please use programs.htop.settings.sort_direction instead.

        Whether to sort descending or not.
      '';
    };

    hideThreads = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.hide_threads instead.

        Hide threads.
      '';
    };

    hideKernelThreads = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Deprecated. Please use programs.htop.settings.hide_kernel_threads instead.

        Hide kernel threads.
      '';
    };

    hideUserlandThreads = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.hide_userland_threads instead.

        Hide userland process threads.
      '';
    };

    shadowOtherUsers = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.shadow_other_users instead.

        Shadow other users' processes.
      '';
    };

    showThreadNames = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.show_thread_names instead.

        Show custom thread names.
      '';
    };

    showProgramPath = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Deprecated. Please use programs.htop.settings.show_program_path instead.

        Show program path.
      '';
    };

    highlightBaseName = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.highlight_base_name instead.

        Highlight program <quote>basename</quote>.
      '';
    };

    highlightMegabytes = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Deprecated. Please use programs.htop.settings.highlight_megabytes instead.

        Highlight large numbers in memory counters.
      '';
    };

    highlightThreads = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Deprecated. Please use programs.htop.settings.highlight_threads instead.

        Display threads in a different color.
      '';
    };

    treeView = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.tree_view instead.

        Tree view.
      '';
    };

    headerMargin = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Deprecated. Please use programs.htop.settings.header_margin instead.

        Leave a margin around header.
      '';
    };

    detailedCpuTime = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.detailed_cpu_time instead.

        Detailed CPU time (System/IO-Wait/Hard-IRQ/Soft-IRQ/Steal/Guest).
      '';
    };

    cpuCountFromZero = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.cpu_count_from_zero instead.

        Count CPUs from 0 instead of 1.
      '';
    };

    showCpuUsage = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.show_cpu_usage instead.

        Show CPU usage frequency.
      '';
    };

    showCpuFrequency = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.show_cpu_frequency instead.

        Show CPU frequency.
      '';
    };

    updateProcessNames = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.update_process_names instead.

        Update process names on every refresh.
      '';
    };

    accountGuestInCpuMeter = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Deprecated. Please use programs.htop.settings.account_guest_in_cpu_meter instead.

        Add guest time in CPU meter percentage.
      '';
    };

    colorScheme = mkOption {
      type = types.enum [ 0 1 2 3 4 5 6 ];
      default = 0;
      example = 6;
      description = ''
        Deprecated. Please use programs.htop.settings.color_scheme instead.

        Which color scheme to use.
      '';
    };

    enableMouse = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Deprecated. Please use programs.htop.settings.enable_mouse instead.

        Enable mouse support.
      '';
    };

    delay = mkOption {
      type = types.int;
      default = 15;
      example = 2;
      description = ''
        Deprecated. Please use programs.htop.settings.delay instead.

        Set the delay between updates, in tenths of seconds.
      '';
    };

    meters = mkOption {
      description = ''
        Deprecated. Please use programs.htop.settings.left_meters,
        programs.htop.settings.left_meter_modes,
        programs.htop.settings.right_meters and
        programs.htop.settings.right_meter_modes instead. Or consider using
        lib.htop.leftMeters and lib.htop.rightMeters.

        Meters shown in the header.
      '';
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
      description = ''
        Deprecated. Please use programs.htop.settings.vim_mode instead.

        Vim key bindings.
      '';
    };
  };

  config = mkIf cfg.enable {
    warnings = optional (cfg.settings == { }) ''
      All individual programs.htop.* options are deprecated. Please use
      programs.htop.settings instead.
    '';

    lib.htop = { inherit fields modes leftMeters rightMeters; };

    home.packages = [ pkgs.htop ];

    xdg.configFile."htop/htoprc".text = let
      leftMeters = map (m: m.kind) cfg.meters.left;
      leftModes = map (m: m.mode) cfg.meters.left;
      rightMeters = map (m: m.kind) cfg.meters.right;
      rightModes = map (m: m.mode) cfg.meters.right;

      settings' = {
        fields = map (n: fields.${n}) cfg.fields;
        sort_key = fields.${cfg.sortKey};
        sort_direction = cfg.sortDescending;
        hide_threads = cfg.hideThreads;
        hide_kernel_threads = cfg.hideKernelThreads;
        hide_userland_threads = cfg.hideUserlandThreads;
        shadow_other_users = cfg.shadowOtherUsers;
        show_thread_names = cfg.showThreadNames;
        show_program_path = cfg.showProgramPath;
        highlight_base_name = cfg.highlightBaseName;
        highlight_megabytes = cfg.highlightMegabytes;
        highlight_threads = cfg.highlightThreads;
        tree_view = cfg.treeView;
        header_margin = cfg.headerMargin;
        detailed_cpu_time = cfg.detailedCpuTime;
        cpu_count_from_zero = cfg.cpuCountFromZero;
        show_cpu_usage = cfg.showCpuUsage;
        show_cpu_frequency = cfg.showCpuFrequency;
        update_process_names = cfg.updateProcessNames;
        account_guest_in_cpu_meter = cfg.accountGuestInCpuMeter;
        color_scheme = cfg.colorScheme;
        enable_mouse = cfg.enableMouse;
        delay = cfg.delay;
        left_meters = leftMeters;
        left_meter_modes = leftModes;
        right_meters = rightMeters;
        right_meter_modes = rightModes;
        vim_mode = cfg.vimMode;
      } // cfg.settings;
    in concatStringsSep "\n" (mapAttrsToList formatOption settings');
  };
}
