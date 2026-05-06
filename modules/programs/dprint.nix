{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.programs.dprint;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.maintainers.rachitvrma ];
  options.programs.dprint = {
    enable = lib.mkEnableOption ''
      dprint: a code formatter for common filetypes like markdown, toml, yaml,
      and many more. See https://dprint.dev/
    '';
    package = lib.mkPackageOption pkgs "dprint" { nullable = true; };
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Settings to add to {file}`$XDG_CONIFG_HOME/dprint/dprint.json`.
      '';
      example = lib.literalExpression ''
        {
          excludes = [
            "**/node_modules"
            "**/*-lock.json"
          ];
          json = { };
          malva = { };
          markdown = { };
          toml = { };
          typescript = { };
          yaml = { };
        }
      '';
    };
    plugins = mkOption {
      type = with types; listOf package;
      default = [ ];
      description = ''
        Plugins to add to dprint's plugin set
      '';
      example = lib.literalExpression ''
        [
          pkgs.dprint-plugins.gplane-pretty_yaml
          pkgs.dprint-plugin-typescript
        ]
      '';
    };
  };
  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."dprint/dprint.json" = mkIf (cfg.plugins != [ ] || cfg.settings != { }) {
      text = builtins.toJSON (
        cfg.settings
        // {
          plugins = map (p: "${p}/plugin.wasm") cfg.plugins;
        }
      );
    };
  };
}
