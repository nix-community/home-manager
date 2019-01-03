{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.lesspipe = {
      enable = mkEnableOption "lesspipe preprocessor for less";

      colorizer = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = literalExample "${pkgs.python3Packages.pygments}/bin/pygmentize";
        description = ''
          Highlight syntax in less using specified highlighter.
        '';
      };
    };
  };

  config = mkIf config.programs.lesspipe.enable {
    home.sessionVariables = {
      LESSOPEN = "|${pkgs.lesspipe}/bin/lesspipe.sh %s";
    }
    //
    optionalAttrs (config.colorizer != null) {
      LESSCOLORIZER = config.colorizer;
    };
  };
}
