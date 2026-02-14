{ config
, lib
, pkgs
, ...
}:
with lib; let
  inherit (lib) generators literalExpression mkEnableOption mkIf mkKeyValue mkOption mkPackageOption types;
  cfg = config.programs.harsh;

  header = ''
    # This is your habits file.
    # It tells harsh what to track and how frequently.
    # 1 means daily, 7 (or 1w) means weekly, 14 every two weeks.
    # You can also track targets within a set number of days.
    # For example, Gym 3 times a week would translate to 3/7.
    # 0 is for tracking a habit. 0 frequency habits will not warn or score.
    # Examples:
  '';

  toHarshConfig = generators.toKeyValue {
    mkKeyValue = key: value: "${key}: ${toString value}";
  };
in
{
  meta.maintainers = [ lib.maintainers.melihdarcanxyz ];

  options.programs.harsh = {
    enable = mkEnableOption "harsh, a CLI habit tracker";

    package = mkPackageOption pkgs "harsh" {
      nullable = true;
    };

    config = mkOption {
      type = types.attrsOf (types.oneOf [ types.str types.int ]);
      default = { };
      example = literalExpression ''
        {
          "Gymmed" = "3/7";
          "Bed by midnight" = 1;
          "Cleaned House" = 7;
          "Called Mom" = "1w";
          "Tracked Finances" = 15;
          "New Skill" = 90;
          "Too much coffee" = 0;
          "Used harsh" = 0;
        }
      '';
      description = ''
        Key-value configuration written to
        {file}`$XDG_CONFIG_HOME/harsh/habits`
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional content written at the end of
        {file}`$XDG_CONFIG_HOME/harsh/habits`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."harsh/habits".text = header + "\n" + (toHarshConfig cfg.habits) + "\n" + cfg.extraConfig;
  };
}
