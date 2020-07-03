{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.alacritty;

in {
  options = {
    programs.alacritty = {
      enable = mkEnableOption "Alacritty";

      package = mkOption {
        type = types.package;
        default = pkgs.alacritty;
        defaultText = literalExample "pkgs.alacritty";
        description = "The Alacritty package to install.";
      };

      settings = mkOption {
        type = types.attrs;
        default = { };
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
      home.packages = [ cfg.package ];

      xdg.configFile."alacritty/alacritty.yml" = mkIf (cfg.settings != { }) {
        text =
          replaceStrings [ "\\\\" ] [ "\\" ] (builtins.toJSON cfg.settings);
      };
    })
  ];
}
