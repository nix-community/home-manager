{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.lsd;

  yamlFormat = pkgs.formats.yaml { };

  aliases = {
    ls = "${pkgs.lsd}/bin/lsd";
    ll = "${pkgs.lsd}/bin/lsd -l";
    la = "${pkgs.lsd}/bin/lsd -A";
    lt = "${pkgs.lsd}/bin/lsd --tree";
    lla = "${pkgs.lsd}/bin/lsd -lA";
    llt = "${pkgs.lsd}/bin/lsd -l --tree";
  };

in {
  meta.maintainers = [ ];

  options.programs.lsd = {
    enable = mkEnableOption "lsd";

    enableAliases = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to enable recommended lsd aliases.
      '';
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = {
        date = "relative";
        ignore-globs = [ ".git" ".hg" ];
      };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/lsd/config.yaml`. See
        <https://github.com/Peltoche/lsd#config-file-content>
        for supported values.
      '';
    };

    colors = mkOption {
      type = yamlFormat.type;
      default = { };
      example = {
        size = {
          none = "grey";
          small = "yellow";
          large = "dark_yellow";
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/lsd/colors.yaml`. See
        <https://github.com/lsd-rs/lsd/tree/v1.0.0#color-theme-file-content> for
        supported colors.

        If this option is non-empty then the `color.theme` option is
        automatically set to `"custom"`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.lsd ];

    programs.bash.shellAliases = mkIf cfg.enableAliases aliases;

    programs.zsh.shellAliases = mkIf cfg.enableAliases aliases;

    programs.fish.shellAliases = mkIf cfg.enableAliases aliases;

    programs.lsd =
      mkIf (cfg.colors != { }) { settings.color.theme = "custom"; };

    xdg.configFile."lsd/colors.yaml" = mkIf (cfg.colors != { }) {
      source = yamlFormat.generate "lsd-colors" cfg.colors;
    };

    xdg.configFile."lsd/config.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "lsd-config" cfg.settings;
    };
  };
}
