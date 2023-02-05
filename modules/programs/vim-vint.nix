{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vim-vint;

  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = [ maintainers.tomodachi94 ];

  options = {
    programs.vim-vint = {
      enable = mkEnableOption "the Vint linter for Vimscript";
      package = mkPackageOption pkgs "vim-vint" { };

      settings = mkOption {
        type = yamlFormat.type;
        default = { };
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/.vintrc.yaml</filename>
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile.".vintrc.yaml".source =
      yamlFormat.generate "vim-vint-config" cfg.settings;
  };
}
