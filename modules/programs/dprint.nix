{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkOption;
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
        Settings to add to {file}`$XDG_CONFIG_HOME/dprint/dprint.json`.
      '';
      example = lib.literalExpression ''
        {
          excludes = [
            "**/node_modules"
            "**/*-lock.json"
          ];
          plugins = [
            "https://plugins.dprint.dev/typescript-0.96.1.wasm"
            "''${pkgs.dprint-plugins.g-plane-pretty_yaml}/plugin.wasm"
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
  };
  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."dprint/dprint.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "hm_dprintdprint.json" cfg.settings;
    };
  };
}
