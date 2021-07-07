{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.flavours;

  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ maintainers.misterio77 ];

  options.programs.flavours = {
    enable = mkEnableOption "Flavours";

    package = mkOption {
      type = types.package;
      default = pkgs.flavours;
      defaultText = literalExample "pkgs.flavours";
      description = "The package to use for the flavours binary.";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      defaultText = literalExample "{ }";
      example = literalExample ''
        {
          shell = "bash -c '{}'";
          item = [
            {
              file = "~/.config/alacritty/colors.yml";
              template = "alacritty";
              subtemplate = "default-256";
              rewrite = true;
            }
            {
              file = "~/.config/sway/colors";
              template = "sway";
              subtemplate = "colors";
              hook = "swaymsg reload";
              rewrite = true;
            }
          ];
        }
      '';
      description = ''
        Configuration written to
        <filename>~/.config/flavours/config.toml</filename>.
        </para><para>
        See <link xlink:href="https://github.com/Misterio77/flavours#setup" /> for all options
        and some examples.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."flavours/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "flavours-config" cfg.settings;
    };
  };
}
