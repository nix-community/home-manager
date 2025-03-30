{ config, lib, pkgs, ... }:
let

  cfg = config.programs.vim-vint;

  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = [ lib.maintainers.tomodachi94 ];

  options = {
    programs.vim-vint = {
      enable = lib.mkEnableOption "the Vint linter for Vimscript";
      package = lib.mkPackageOption pkgs "vim-vint" { nullable = true; };

      settings = lib.mkOption {
        type = yamlFormat.type;
        default = { };
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/.vintrc.yaml`
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile.".vintrc.yaml".source =
      yamlFormat.generate "vim-vint-config" cfg.settings;
  };
}
