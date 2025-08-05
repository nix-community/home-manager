{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    types
    ;

  cfg = config.programs.sherlock;

  tomlFormat = pkgs.formats.toml { };
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.maintainers.khaneliman ];

  options.programs.sherlock = {
    enable = mkEnableOption "sherlock launcher" // {
      description = ''
        Enable Sherlock, a fast and lightweight application launcher for Wayland.

        See <https://github.com/Skxxtz/sherlock> for more information.
      '';
    };

    package = mkPackageOption pkgs "sherlock" {
      default = "sherlock-launcher";
      nullable = true;
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Configuration for Sherlock.

        Written to `config.toml`.

        See <https://github.com/Skxxtz/sherlock/blob/main/docs/config.md> for available options.
      '';
      example = {
        theme = "dark";
        width = 500;
        max_results = 8;
      };
    };

    aliases = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Defines custom aliases.

        Written to `sherlock_alias.json`.

        See <https://github.com/Skxxtz/sherlock/blob/main/docs/aliases.md> for more information.
      '';
      example = {
        "NixOS Wiki" = {
          name = "NixOS Wiki";
          icon = "nixos";
          exec = "firefox https://nixos.wiki/index.php?search=%s";
          keywords = "nix wiki docs";
        };
      };
    };

    ignore = mkOption {
      type = types.lines;
      default = "";
      description = ''
        A list of desktop entry IDs to ignore.

        Written to `sherlockignore`.

        See <https://github.com/Skxxtz/sherlock/blob/main/docs/sherlockignore.md> for more information.
      '';
      example = ''
        hicolor-icon-theme.desktop
        user-dirs.desktop
      '';
    };

    launchers = mkOption {
      inherit (jsonFormat) type;
      default = [ ];
      description = ''
        Defines fallback launchers.

        Written to `fallback.json`.

        See <https://github.com/Skxxtz/sherlock/blob/main/docs/launchers.md> for more information.
      '';
    };

    style = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Custom CSS to style the Sherlock UI.

        Written to `main.css`.
      '';
      example = ''
        window {
          background-color: #2E3440;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.sherlock" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "sherlock/config.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "sherlock-config.toml" cfg.settings;
      };

      "sherlock/sherlock_alias.json" = mkIf (cfg.aliases != { }) {
        source = jsonFormat.generate "sherlock_alias.json" cfg.aliases;
      };

      "sherlock/fallback.json" = mkIf (cfg.launchers != [ ]) {
        source = jsonFormat.generate "sherlock-fallback.json" cfg.launchers;
      };

      "sherlock/sherlockignore" = mkIf (cfg.ignore != "") {
        text = cfg.ignore;
      };

      "sherlock/main.css" = mkIf (cfg.style != "") {
        text = cfg.style;
      };
    };
  };
}
