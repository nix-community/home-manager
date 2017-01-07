{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.beets;

in

{
  options = {
    programs.beets = {
      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "Configuration written to ~/.config/beets/config.yaml";
      };
    };
  };

  config = mkIf (cfg.settings != {}) {
    home.packages = [ pkgs.beets ];

    home.file.".config/beets/config.yaml".text =
        builtins.toJSON config.programs.beets.settings;
  };
}
