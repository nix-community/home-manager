{ pkgs, lib, config, ... }:

let
  inherit (lib) mkEnableOption mkPackageOption mkOption mkIf literalExpression;

  cfg = config.programs.fastfetch;

  jsonFormat = pkgs.formats.json { };
in {
  meta.maintainers = with lib.hm.maintainers; [ afresquet ];

  options.programs.fastfetch = {
    enable = mkEnableOption "Fastfetch";

    package = mkPackageOption pkgs "fastfetch" { };

    settings = mkOption {
      type = jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          logo = {
            source = "nixos_small";
            padding = {
              right = 1;
            };
          };
          display = {
            binaryPrefix = "si";
            color = "blue";
            separator = "  ";
          };
          modules = [
            {
              type = "datetime";
              key = "Date";
              format = "{1}-{3}-{11}";
            }
            {
              type = "datetime";
              key = "Time";
              format = "{14}:{17}:{20}";
            }
            "break"
            "player"
            "media"
          ];
        };
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/fastfetch/config.jsonc`.
        See <https://github.com/fastfetch-cli/fastfetch/wiki/Json-Schema>
        for the documentation.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."fastfetch/config.jsonc" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "config.jsonc" cfg.settings;
    };
  };
}
