{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bat;

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.bat = {
    enable = mkEnableOption "bat, a cat clone with wings";

    config = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        theme = "TwoDark";
        pager = "less -FR";
      };
      description = ''
        Bat configuration.
      '';
    };

    themes = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      example = literalExample ''
        {
          dracula = builtins.readFile (pkgs.fetchFromGitHub {
            owner = "dracula";
            repo = "sublime"; # Bat uses sublime syntax for its themes
            rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
            sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
          } + "/Dracula.tmTheme");
        }
      '';
      description = ''
        Additional themes to provide.
      '';
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.bat ];

    xdg.configFile = mkMerge ([{
      "bat/config" = mkIf (cfg.config != { }) {
        text = concatStringsSep "\n"
          (mapAttrsToList (n: v: ''--${n}="${v}"'') cfg.config);
      };
    }] ++ flip mapAttrsToList cfg.themes
      (name: body: { "bat/themes/${name}.tmTheme" = { text = body; }; }));
  };
}
