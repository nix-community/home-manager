{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.beets;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.beets = {
      settings = mkOption {
        type = types.attrs;
        default = {};
        description = ''
          Configuration written to
          <filename>~/.config/beets/config.yaml</filename>
        '';
      };
    };
  };

  config = mkIf (cfg.settings != {}) {
    home.packages = [ pkgs.beets ];

    home.file.".config/beets/config.yaml".text =
        builtins.toJSON config.programs.beets.settings;
  };
}
