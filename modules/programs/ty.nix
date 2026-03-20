{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    literalExpression
    ;

  tomlFormat = pkgs.formats.toml { };
  cfg = config.programs.ty;
in
{
  meta.maintainers = with lib.maintainers; [ mirkolenz ];

  options.programs.ty = {
    enable = mkEnableOption "ty";

    package = mkPackageOption pkgs "ty" { nullable = true; };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          rules.index-out-of-bounds = "ignore";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/ty/ty.toml`.
        See <https://docs.astral.sh/ty/configuration/>
        and <https://docs.astral.sh/ty/reference/configuration/>
        for more information.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."ty/ty.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "ty-config.toml" cfg.settings;
    };
  };
}
