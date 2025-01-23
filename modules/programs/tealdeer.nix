{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.tealdeer;

  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;

  tomlFormat = pkgs.formats.toml { };

  settingsFormat = let
    updatesSection = types.submodule {
      options = {
        auto_update = mkEnableOption "auto-update";

        auto_update_interval_hours = mkOption {
          type = types.ints.positive;
          default = 720;
          example = literalExpression "24";
          description = ''
            Duration, since the last cache update, after which the cache will be refreshed.
            This parameter is ignored if {var}`auto_update` is set to `false`.
          '';
        };
      };
    };
  in types.submodule {
    freeformType = tomlFormat.type;
    options = {
      updates = mkOption {
        type = updatesSection;
        default = { };
        description = ''
          Tealdeer can refresh the cache automatically when it is outdated.
          This behavior can be configured in the updates section.
        '';
      };
    };
  };

in {
  meta.maintainers = [ hm.maintainers.pedorich-n ];

  imports = [
    (mkRemovedOptionModule [ "programs" "tealdeer" "updateOnActivation" ] ''
      Updating tealdeer's cache requires network access.
      The activation script should be fast and idempotent, so the option was removed.
      Please use

        `programs.tealdeer.settings.updates.auto_update = true`

      instead, to make sure tealdeer's cache is updated periodically.
    '')
  ];

  options.programs.tealdeer = {
    enable = mkEnableOption "Tealdeer";

    settings = mkOption {
      type = types.nullOr settingsFormat;
      default = null;
      example = literalExpression ''
        {
          display = {
            compact = false;
            use_pager = true;
          };
          updates = {
            auto_update = false;
          };
        };
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/tealdeer/config.toml` on Linux or
        {file}`$HOME/Library/Application Support/tealdeer/config.toml` on Darwin.
        See <https://tealdeer-rs.github.io/tealdeer/config.html> for more information.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.tealdeer ];

    home.file."${configDir}/tealdeer/config.toml" =
      mkIf (cfg.settings != null && cfg.settings != { }) {
        source = tomlFormat.generate "tealdeer-config" cfg.settings;
      };
  };
}
