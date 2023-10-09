{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.joshuto;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ hm.maintainers.rasmus-kirk ];

  options.programs.joshuto = {
    enable = mkEnableOption "joshuto file manager";

    package = mkOption {
      type = types.package;
      default = pkgs.joshuto;
      defaultText = literalExpression "pkgs.joshuto";
      description = "The package to use for joshuto.";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/joshuto/joshuto.toml`.

        See <https://github.com/kamiyaa/joshuto/blob/main/docs/configuration/joshuto.toml.md>
        for the full list of options.
      '';
    };

    keymap = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/joshuto/keymap.toml`.

        See <https://github.com/kamiyaa/joshuto/blob/main/docs/configuration/keymap.toml.md>
        for the full list of options. Note that this option will overwrite any existing keybinds.
      '';
    };

    mimetype = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/joshuto/mimetype.toml`.

        See <https://github.com/kamiyaa/joshuto/blob/main/docs/configuration/mimetype.toml.md>
        for the full list of options
      '';
    };

    theme = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/joshuto/theme.toml`.

        See <https://github.com/kamiyaa/joshuto/blob/main/docs/configuration/theme.toml.md>
        for the full list of options
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "joshuto/joshuto.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "joshuto-settings" cfg.settings;
      };
      "joshuto/keymap.toml" = mkIf (cfg.keymap != { }) {
        source = tomlFormat.generate "joshuto-keymap" cfg.keymap;
      };
      "joshuto/mimetype.toml" = mkIf (cfg.mimetype != { }) {
        source = tomlFormat.generate "joshuto-mimetype" cfg.mimetype;
      };
      "joshuto/theme.toml" = mkIf (cfg.theme != { }) {
        source = tomlFormat.generate "joshuto-theme" cfg.theme;
      };
    };
  };
}
