{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    mkMerge
    types
    literalExpression
    mapAttrs'
    nameValuePair
    ;

  cfg = config.programs.rio;

  settingsFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.otavio ];

  options.programs.rio = {
    enable = mkEnableOption null // {
      description = ''
        Enable Rio, a terminal built to run everywhere, as a native desktop applications by
        Rust/WebGPU or even in the browsers powered by WebAssembly/WebGPU.
      '';
    };

    package = mkPackageOption pkgs "rio" { nullable = true; };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/rio/config.toml`. See
        <https://raphamorim.io/rio/docs/#configuration-file> for options.
      '';
    };

    themes = mkOption {
      type = with types; attrsOf (either settingsFormat.type path);
      default = { };
      description = ''
        Theme files written to {file}`$XDG_CONFIG_HOME/rio/themes/`. See
        <https://rioterm.com/docs/config#building-your-own-theme> for
        supported values.
      '';
      example = literalExpression ''
        {
          foobar.colors = {
            background = "#282a36";
            green = "#50fa7b";
            dim-green = "#06572f";
          };
        }
      '';
    };

    defaultTerminal = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to set {command}`rio` as the default terminal.";
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];
    }

    # Only manage configuration if not empty
    (mkIf (cfg.settings != { }) {
      xdg.configFile."rio/config.toml".source =
        if builtins.isPath cfg.settings then
          cfg.settings
        else
          settingsFormat.generate "rio.toml" cfg.settings;
    })

    (mkIf (cfg.themes != { }) {
      xdg.configFile = mapAttrs' (
        name: value:
        nameValuePair "rio/themes/${name}.toml" {
          source =
            if builtins.isPath value then value else settingsFormat.generate "rio-theme-${name}.toml" value;
        }
      ) cfg.themes;
    })

    (mkIf (cfg.defaultTerminal) {
      home.sessionVariables.TERMINAL = lib.getExe cfg.package;
      systemd.user.sessionVariables = mkIf pkgs.stdenv.isLinux {
        TERMINAL = lib.getExe cfg.package;
      };
    })
  ]);
}
