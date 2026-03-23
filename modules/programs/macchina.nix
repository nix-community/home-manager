{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.macchina;
  tomlFormat = pkgs.formats.toml { };

  colorType = types.str;

  readoutType = types.enum [
    "Host"
    "Machine"
    "Kernel"
    "Distribution"
    "OperatingSystem"
    "DesktopEnvironment"
    "WindowManager"
    "Resolution"
    "Backlight"
    "Packages"
    "LocalIP"
    "Terminal"
    "Shell"
    "Uptime"
    "Processor"
    "ProcessorLoad"
    "Memory"
    "Battery"
    "GPU"
    "DiskSpace"
  ];

  paletteModule = types.submodule {
    options = {
      type = mkOption {
        type = types.nullOr (
          types.enum [
            "Dark"
            "Light"
            "Full"
          ]
        );
        default = null;
        description = "Color set to use for the palette. Case-sensitive.";
      };
      glyph = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Glyph for the palette. Append a trailing space to separate glyphs.";
      };
      visible = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether to show the palette.";
      };
    };
  };

  barModule = types.submodule {
    options = {
      glyph = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Glyph to use for all bars.";
      };
      symbol_open = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Opening delimiter character. Must be a single character.";
      };
      symbol_close = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Closing delimiter character. Must be a single character.";
      };
      visible = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether to show bars.";
      };
      hide_delimiters = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether to hide bar delimiters.";
      };
    };
  };

  innerMarginModule = types.submodule {
    options = {
      x = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = "Horizontal margin between content and the box border.";
      };
      y = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = "Vertical margin between content and the box border.";
      };
    };
  };

  boxModule = types.submodule {
    options = {
      title = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Hydrogen";
        description = "Title displayed on the box. Omitted from config when null.";
      };
      border = mkOption {
        type = types.nullOr (
          types.enum [
            "plain"
            "thick"
            "rounded"
            "double"
          ]
        );
        default = null;
        description = "Border style for the box.";
      };
      visible = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether to show the box.";
      };
      inner_margin = mkOption {
        type = types.nullOr innerMarginModule;
        default = null;
        description = "Inner margin between content and the box border.";
      };
    };
  };

  customAsciiModule = types.submodule {
    options = {
      color = mkOption {
        type = types.nullOr colorType;
        default = null;
        example = "Cyan";
        description = ''
          Color of the ASCII art. Omitted when null.
          Accepts hex ("#00FF00"), indexed ("046"), or named colors (e.g. "Green").
        '';
      };
      path = mkOption {
        type = types.nullOr (types.either types.str types.path);
        default = null;
        example = "~/ascii/arch_linux";
        description = "Path to a file containing ASCII art. ANSI escape sequences are supported.";
      };
    };
  };

  randomizeModule = types.submodule {
    options = {
      key_color = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether to randomize the key color.";
      };
      separator_color = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether to randomize the separator color.";
      };
      pool = mkOption {
        type = types.nullOr (
          types.enum [
            "hexadecimal"
            "indexed"
            "base"
          ]
        );
        default = null;
        description = ''
          Pool of colors to draw from when randomizing. Omitted when null.
          - "hexadecimal": random color #000000–#FFFFFF
          - "indexed": random color 0–255
          - "base": random from black, white, red, green, blue, yellow, magenta, cyan
        '';
      };
    };
  };

  keysModule = types.submodule {
    options = {
      host = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Host readout.";
      };
      kernel = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Kernel readout.";
      };
      os = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the OperatingSystem readout.";
      };
      machine = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Machine readout.";
      };
      de = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the DesktopEnvironment readout.";
      };
      wm = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the WindowManager readout.";
      };
      distro = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Distribution readout.";
      };
      terminal = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Terminal readout.";
      };
      shell = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Shell readout.";
      };
      packages = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Packages readout.";
      };
      uptime = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Uptime readout.";
      };
      local_ip = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the LocalIP readout.";
      };
      memory = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Memory readout.";
      };
      battery = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Battery readout.";
      };
      backlight = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Backlight readout.";
      };
      resolution = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Resolution readout.";
      };
      cpu = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the Processor readout.";
      };
      cpu_load = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the ProcessorLoad readout.";
      };
      gpu = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the GPU readout.";
      };
      disk_space = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Label for the DiskSpace readout.";
      };
    };
  };

  themeModule = types.submodule {
    options = {
      spacing = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = "Spacing between the separator and adjacent content.";
      };
      padding = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = "Padding between content and its surroundings.";
      };
      hide_ascii = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether to disable ASCII rendering entirely.";
      };
      prefer_small_ascii = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Always use smaller variants of built-in ASCII art.";
      };
      separator = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Glyph to use as the separator.";
      };
      key_color = mkOption {
        type = types.nullOr colorType;
        default = null;
        example = "Cyan";
        description = ''
          Color of the keys. Omitted when null.
          Accepts hex ("#00FF00"), indexed ("046"), or named colors (e.g. "Cyan").
        '';
      };
      separator_color = mkOption {
        type = types.nullOr colorType;
        default = null;
        example = "White";
        description = ''
          Color of the separator. Omitted when null.
          Accepts hex ("#00FF00"), indexed ("046"), or named colors (e.g. "White").
        '';
      };
      palette = mkOption {
        type = types.nullOr paletteModule;
        default = null;
        description = ''
          Palette section. Displays the active colorscheme of your terminal emulator.
          Omit to exclude the [palette] section entirely.
        '';
      };
      bar = mkOption {
        type = types.nullOr barModule;
        default = null;
        description = ''
          Bar section. Replaces data ranging from 0–100% with visual bars.
          Omit to exclude the [bar] section entirely.
        '';
      };
      box = mkOption {
        type = types.nullOr boxModule;
        default = null;
        description = ''
          Box section. Renders a box around system information.
          Omit to exclude the [box] section entirely.
        '';
      };
      custom_ascii = mkOption {
        type = types.nullOr customAsciiModule;
        default = null;
        description = ''
          Custom ASCII section. Specify your own ASCII art file.
          Omit to exclude the [custom_ascii] section entirely.
        '';
      };
      randomize = mkOption {
        type = types.nullOr randomizeModule;
        default = null;
        description = ''
          Randomize section. Controls random color selection for keys and separators.
          Omit to exclude the [randomize] section entirely.
        '';
      };
      keys = mkOption {
        type = types.nullOr keysModule;
        default = null;
        description = ''
          Keys section. Overrides the display label for each readout.
          Omit to exclude the [keys] section entirely.
        '';
      };
    };
  };

  # Strip null values recursively before handing off to the TOML generator.
  stripNulls = lib.filterAttrsRecursive (_: v: v != null);

in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.programs.macchina = {
    enable = lib.mkEnableOption "macchina system information fetcher";

    package = lib.mkPackageOption pkgs "macchina" { nullable = true; };

    settings = {
      interface = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "wlan0";
        description = "Network interface to use for the LocalIP readout. Omitted when null.";
      };

      long_uptime = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Show lengthened uptime output.";
      };

      long_shell = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Show lengthened shell output.";
      };

      long_kernel = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Show lengthened kernel output.";
      };

      current_shell = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Show the current shell rather than the user's default shell.";
      };

      physical_cores = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Show physical CPU core count rather than logical core count.";
      };

      disks = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        example = [
          "/"
          "/home/user"
        ];
        description = "Disks to show disk usage for.";
      };

      disk_space_percentage = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Show percentage next to disk space information.";
      };

      memory_percentage = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Show percentage next to memory information.";
      };

      theme = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Hydrogen";
        description = ''
          Name of the theme to use, without the .toml extension. Case-sensitive.
          Must correspond to a file in the macchina themes directory, or be defined
          in {option}`programs.macchina.themes`.
          Omitted when null.
        '';
      };

      show = mkOption {
        type = types.nullOr (types.listOf readoutType);
        default = null;
        example = literalExpression ''[ "Battery" "Memory" "Processor" "Shell" ]'';
        description = ''
          Display only the specified readouts. When null, all readouts are shown.
          Values are case-sensitive.
        '';
      };
    };

    themes = mkOption {
      type = types.attrsOf themeModule;
      default = { };
      example = literalExpression ''
        {
          Hydrogen = {
            spacing = 2;
            padding = 0;
            hide_ascii = true;
            separator = ">";
            key_color = "Cyan";
            separator_color = "White";

            palette = {
              type = "Full";
              visible = false;
            };

            bar = {
              glyph = "o";
              symbol_open = "[";
              symbol_close = "]";
              hide_delimiters = true;
              visible = true;
            };

            box = {
              border = "plain";
              visible = true;
              inner_margin = { x = 1; y = 0; };
            };

            randomize = {
              key_color = false;
              separator_color = false;
            };

            keys = {
              host = "Host";
              kernel = "Kernel";
              battery = "Battery";
              os = "OS";
              de = "DE";
              wm = "WM";
              distro = "Distro";
              terminal = "Terminal";
              shell = "Shell";
              packages = "Packages";
              uptime = "Uptime";
              memory = "Memory";
              machine = "Machine";
              local_ip = "Local IP";
              backlight = "Brightness";
              resolution = "Resolution";
              cpu_load = "CPU Load";
              cpu = "CPU";
              gpu = "GPU";
              disk_space = "Disk Space";
            };
          };
        }
      '';
      description = ''
        Attribute set of macchina themes. Each entry is written to
        {file}`$XDG_CONFIG_HOME/macchina/themes/<name>.toml`.

        Theme names are case-sensitive. A theme defined here can be activated
        by setting {option}`programs.macchina.settings.theme` to its name.

        See <https://github.com/Macchina-CLI/macchina/wiki/Customization>
        for details.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile =
      let
        settingsAttrs = stripNulls {
          inherit (cfg.settings)
            interface
            long_uptime
            long_shell
            long_kernel
            current_shell
            physical_cores
            disks
            disk_space_percentage
            memory_percentage
            theme
            show
            ;
        };

        themeFiles = lib.mapAttrs' (
          name: theme:
          lib.nameValuePair "macchina/themes/${name}.toml" {
            source = tomlFormat.generate "macchina-theme-${name}" (stripNulls theme);
          }
        ) cfg.themes;
      in
      lib.optionalAttrs (settingsAttrs != { }) {
        "macchina/macchina.toml".source = tomlFormat.generate "macchina.toml" settingsAttrs;
      }
      // themeFiles;
  };
}
