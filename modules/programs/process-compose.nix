{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkIf;
  cfg = config.programs.process-compose;
  settingsFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.bbigras ];
  options.programs.process-compose = {
    enable = lib.mkEnableOption "the process-compose orchestrator";
    package = lib.mkPackageOption pkgs "process-compose" { nullable = true; };
    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        The process-compose configuration.
        See [docs](`https://f1bonacc1.github.io/process-compose/tui/?h=settings.yaml#tui-state-settings`).
        for the full list of options.
      '';
      example = literalExpression ''
        {
          theme = "Cobalt";
        }
      '';
    };
  };
  config =
    let
      configDir =
        if (pkgs.stdenv.targetPlatform.isDarwin) then
          "Library/Application Support/process-compose"
        else
          "${config.xdg.configHome}/process-compose";
    in
    mkIf cfg.enable {
      home = {
        packages = mkIf (cfg.package != null) [ cfg.package ];

        file.process-compose-settings = {
          enable = cfg.settings != { };
          target = "${configDir}/settings.yaml";
          source = settingsFormat.generate "process-compose-settings" cfg.settings;
        };
      };
    };
}
