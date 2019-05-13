{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.alacritty;

in

{
  options = {
    programs.alacritty = {
      enable = mkEnableOption "Alacritty";

      settings = mkOption {
        type = types.attrs;
        default = {};
        example = literalExample ''
          {
            window.dimensions = {
              lines = 3;
              columns = 200;
            };
            key_bindings = [
              {
                key = "K";
                mods = "Control";
                chars = "\\x0c";
              }
            ];
          }
        '';
        description = ''
          Configuration written to
          <filename>~/.config/alacritty/alacritty.yml</filename>. See
          <link xlink:href="https://github.com/jwilm/alacritty/blob/master/alacritty.yml"/>
          for the default configuration.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [ pkgs.alacritty ];

      xdg.configFile."alacritty/alacritty.yml" = mkIf (cfg.settings != {}) {
        text = replaceStrings ["\\\\"] ["\\"] (builtins.toJSON cfg.settings);
      };
    })
  ];
}
