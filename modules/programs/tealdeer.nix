{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.tealdeer;

  packageVersion = lib.getVersion cfg.package;
  configDir =
    if (pkgs.stdenv.hostPlatform.isDarwin && lib.versionOlder packageVersion "1.9.0") then
      "Library/Application Support"
    else
      config.xdg.configHome;

  tomlFormat = pkgs.formats.toml { };

  settingsFormat =
    let
      updatesSection = lib.types.submodule {
        freeformType = tomlFormat.type;
        options = {
          auto_update = lib.mkEnableOption "auto-update";

          auto_update_interval_hours = lib.mkOption {
            type = lib.types.ints.positive;
            default = 720;
            example = 24;
            description = ''
              Duration, since the last cache update, after which the cache will be refreshed.
              This parameter is ignored if {var}`auto_update` is set to `false`.
            '';
          };
        };
      };
    in
    lib.types.submodule {
      freeformType = tomlFormat.type;
      options = {
        updates = lib.mkOption {
          type = updatesSection;
          default = { };
          description = ''
            Tealdeer can refresh the cache automatically when it is outdated.
            This behavior can be configured in the updates section.
          '';
        };
      };
    };

in
{
  meta.maintainers = [ lib.hm.maintainers.pedorich-n ];

  imports = [
    (lib.mkRemovedOptionModule [ "programs" "tealdeer" "updateOnActivation" ] ''
      Updating tealdeer's cache requires network access.
      The activation script should be fast and idempotent, so the option was removed.
      Please use

        `programs.tealdeer.settings.updates.auto_update = true`

      instead, to make sure tealdeer's cache is updated periodically.
    '')
  ];

  options.programs.tealdeer = {
    enable = lib.mkEnableOption "Tealdeer";

    package = lib.mkPackageOption pkgs "tealdeer" { };

    settings = lib.mkOption {
      type = lib.types.nullOr settingsFormat;
      default = null;
      example = lib.literalExpression ''
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
        Configuration written to {file}`$XDG_CONFIG_HOME/tealdeer/config.toml`.
        See <https://docs.tealdeer.org/stable/config.html> for more information.

        ::: {.note}
        `tealdeeer` versions before `1.9.0` on Darwin used to read the config from
        {file}`$HOME/Library/Application Support/tealdeer/config.toml`.
        In newer versions it respects the XDG directories and
        uses `Library/Application Support` only as fallback.
        :::
      '';
    };

    enableAutoUpdates = lib.mkEnableOption "Auto updates" // {
      default = true;
      example = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];

      file."${configDir}/tealdeer/config.toml" = lib.mkIf (cfg.settings != null && cfg.settings != { }) {
        source = tomlFormat.generate "tealdeer-config" cfg.settings;
      };
    };

    services.tldr-update = lib.mkIf cfg.enableAutoUpdates {
      enable = true;
      inherit (cfg) package;
    };
  };
}
