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
  cfg = config.programs.uv;

in
{
  meta.maintainers = with lib.maintainers; [ mirkolenz ];

  options.programs.uv = {
    enable = mkEnableOption "uv";

    package = mkPackageOption pkgs "uv" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          python-downloads = "never";
          python-preference = "only-system";
          pip.index-url = "https://test.pypi.org/simple";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/uv/uv.toml`.
        See <https://docs.astral.sh/uv/configuration/files/>
        and <https://docs.astral.sh/uv/reference/settings/>
        for more information.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."uv/uv.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "uv-config" cfg.settings;
    };
  };
}
