{ lib }:
let
  inherit (lib)
    mkOption
    types
    literalExpression
    ;
in
{
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
      type = types.nullOr (
        types.listOf (
          types.enum [
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
          ]
        )
      );
      default = null;
      example = literalExpression ''[ "Battery" "Memory" "Processor" "Shell" ]'';
      description = ''
        Display only the specified readouts. When null, all readouts are shown.
        Values are case-sensitive.
      '';
    };
  };
}
