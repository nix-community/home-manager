{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.screen;

in {
  options = {
    programs.screen = {
      enable = mkEnableOption "GNU screen";

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration to write to <filename>~/.screenrc</filename>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.screen ];
    home.file.".screenrc".text = cfg.extraConfig;
  };
}
