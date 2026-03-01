{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.programs.htop;

  formatOption =
    n: v:
    let
      v' = if lib.isBool v then (if v then "1" else "0") else toString v;
    in
    "${n}=${v'}";

  formatMeters = side: meters: {
    "${side}_meters" = lib.concatMap (lib.mapAttrsToList (x: _: x)) meters;
    "${side}_meter_modes" = lib.concatMap (lib.mapAttrsToList (_: y: y)) meters;
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
    TTY = 6;
    TTY_NR = 6;
    TPGID = 7;
    MINFLT = 9;
    CMINFLT = 10;
    MAJFLT = 11;
    CMAJFLT = 12;
    UTIME = 13;
    STIME = 14;
    CUTIME = 15;
    CSTIME = 16;
    PRIORITY = 17;
    NICE = 18;
    STARTTIME = 20;
    PROCESSOR = 37;
    M_VIRT = 38;
    M_SIZE = 38;
    M_RESIDENT = 39;
    M_SHARE = 40;
    M_TRS = 41;
    M_DRS = 42;
    M_LRS = 43;
    M_DT = 44;
    ST_UID = 45;
    PERCENT_CPU = 46;
    PERCENT_MEM = 47;
    USER = 48;
    TIME = 49;
    NLWP = 50;
    TGID = 51;
    PERCENT_NORM_CPU = 52;
    ELAPSED = 53;
    SCHEDULERPOLICY = 54;
    CTID = 99;
    VPID = 100;
    RCHAR = 102;
    VXID = 102;
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
    CTXT = 121;
    SECATTR = 122;
    PROC_COMM = 123;
    PROC_EXE = 124;
    CWD = 125;
    AUTOGROUP_ID = 126;
    AUTOGROUP_NICE = 127;
    CCGROUP = 128;
    CONTAINER = 129;
    M_PRIV = 130;
    GPU_TIME = 131;
    GPU_PERCENT = 132;
    ISCONTAINER = 133;
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

  screenOptions = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Name that shows on the screen tab.";
    };

    fields = lib.mkOption {
      type = lib.types.oneOf [
        lib.types.str
        (lib.types.listOf lib.types.str)
      ];
      default = "PID USER M_VIRT STATE PERCENT_CPU PERCENT_MEM TIME Command";
      description = "What fields to show in the screen.";
    };

    all_branches_collapsed = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to collapse all branches in the tree view.";
    };

    sort_direction = lib.mkOption {
      type = lib.types.enum [
        (-1)
        1
      ];
      default = -1;
      description = "Whether to sort ascending or descending.";
    };
    sort_key = lib.mkOption {
      type = lib.types.str;
      example = "PERCENT_MEM";
      description = "Key to sort by.";
    };

    tree_sort_direction = lib.mkOption {
      type = lib.types.enum [
        (-1)
        1
      ];
      default = -1;
      description = "Whether to sort the tree ascending or descending.";
    };
    tree_sort_key = lib.mkOption {
      type = lib.types.str;
      example = "PERCENT_MEM";
      description = "Key to sort the three by.";
    };

    tree_view = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the use a tree view.";
    };

    tree_view_always_by_pid = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whther the tree view groups by pid.";
    };
  };

in
{
  meta.maintainers = [ lib.hm.maintainers.bjpbakker ];

  options.programs.htop = {
    enable = lib.mkEnableOption "htop";

    settings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          bool
          int
          str
          (listOf (oneOf [
            int
            str
          ]))
        ]);
      default = { };
      example = lib.literalExpression ''
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
        {file}`$XDG_CONFIG_HOME/htop/htoprc`.
      '';
    };

    screens = lib.mkOption {
      type = lib.hm.types.dagOf (
        lib.types.submodule (
          { dagName, ... }:
          {
            options = screenOptions;
            config.name = lib.mkDefault dagName;
          }
        )
      );
      default = { };
      example = lib.literalExpression ''
        {
          "Main" = {
            fields = "PID USER PRIORITY NICE M_VIRT M_RESIDENT M_SHARE STATE PERCENT_CPU PERCENT_MEM TIME Command";
            sort_key = "PERCENT_MEM";
            tree_sort_key = "PERCENT_MEM";
            tree_view = false;
            tree_view_always_by_pid = false;
            sort_direction = -1;
            tree_sort_direction = -1;
            all_branches_collapsed = false;
          };
          "I/O" = lib.hm.dag.entryAfter ["Main"] {
            fields = "PID STATE STARTTIME M_RESIDENT COMM EXE USER IO_PRIORITY IO_RATE IO_READ_RATE IO_WRITE_RATE";
            sort_key = "IO_RATE";
            tree_sort_key = "PID";
            tree_view = false;
            tree_view_always_by_pid = false;
            sort_direction = -1;
            tree_sort_direction = -1;
            all_branches_collapsed = false;
          };
        };
      '';
      description = ''
        List of screens.
      '';
    };

    package = lib.mkPackageOption pkgs "htop" { };
  };

  config = lib.mkIf cfg.enable {
    lib.htop = {
      inherit
        fields
        modes
        leftMeters
        rightMeters
        bar
        text
        graph
        led
        blank
        ;
    };

    home.packages = [ cfg.package ];

    xdg.configFile."htop" =
      let

        formatOptions = lib.mapAttrsToList formatOption;

        hasScreens = cfg.screens != { };

        settings =
          let
            # old (no screen) configuration support
            defaultFields =
              let
                defaults = with fields; [
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
              in
              if isDarwin then lib.remove fields.M_SHARE defaults else defaults;

            oldDefaults = lib.optionalAttrs (!hasScreens) { fields = defaultFields; };

            leading = lib.optionalAttrs (cfg.settings ? header_layout) {
              inherit (cfg.settings) header_layout;
            };

            settings' = oldDefaults // (removeAttrs cfg.settings (lib.attrNames leading));
          in
          formatOptions leading ++ formatOptions settings';

        screens =
          let
            formatOption' = k: formatOption ".${k}";
            formatScreen =
              { name, fields, ... }@screen:
              let
                options = removeAttrs screen [
                  "fields"
                  "name"
                ];
                newScreen = "screen:${formatOption name fields}";
              in
              [ newScreen ] ++ lib.mapAttrsToList formatOption' options;

            screens' =
              let
                sorted = lib.hm.dag.topoSort cfg.screens;
              in
              sorted.result or (abort "Dependency cycle in htop screens: ${builtins.toJSON sorted}");

          in
          lib.concatMap (x: formatScreen x.data) screens';

      in
      lib.mkIf (cfg.settings != { } || hasScreens) {
        source = pkgs.writeTextDir "htoprc" (lib.concatStringsSep "\n" (settings ++ screens) + "\n");
      };
  };
}
