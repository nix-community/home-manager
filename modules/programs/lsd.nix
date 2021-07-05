{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.lsd;

  yamlFormat = pkgs.formats.yaml { };

  aliases = {
    ls = "${pkgs.lsd}/bin/lsd";
    ll = "${pkgs.lsd}/bin/lsd -l";
    la = "${pkgs.lsd}/bin/lsd -a";
    lt = "${pkgs.lsd}/bin/lsd --tree";
    lla = "${pkgs.lsd}/bin/lsd -la";
  };

in {
  meta.maintainers = [ maintainers.marsam ];

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
        <filename>~/.config/lsd/config.yaml</filename>. See
        <link xlink:href="https://github.com/Peltoche/lsd#config-file-content"/>
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.lsd ];

    programs.bash.shellAliases = mkIf cfg.enableAliases aliases;

    programs.zsh.shellAliases = mkIf cfg.enableAliases aliases;

    programs.fish.shellAliases = mkIf cfg.enableAliases aliases;

    xdg.configFile."lsd/config.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "lsd-config" cfg.settings;
    };
  };
}
