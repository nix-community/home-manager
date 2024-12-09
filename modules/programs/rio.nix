{ lib, pkgs, config, ... }:
let
  cfg = config.programs.rio;

  settingsFormat = pkgs.formats.toml { };
in {
  options.programs.rio = {
    enable = lib.mkEnableOption null // {
      description = ''
        Enable Rio, a terminal built to run everywhere, as a native desktop applications by
        Rust/WebGPU or even in the browsers powered by WebAssembly/WebGPU.
      '';
    };

    package = lib.mkPackageOption pkgs "rio" { };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/rio/config.toml`. See
        <https://raphamorim.io/rio/docs/#configuration-file> for options.
      '';
    };
  };
  meta.maintainers = [ lib.maintainers.otavio ];

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [ cfg.package ];
    }

    # Only manage configuration if not empty
    (lib.mkIf (cfg.settings != { }) {
      xdg.configFile."rio/config.toml".source = if lib.isPath cfg.settings then
        cfg.settings
      else
        settingsFormat.generate "rio.toml" cfg.settings;
    })
  ]);
}
