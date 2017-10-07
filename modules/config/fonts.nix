{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    fonts.fonts = mkOption {
      type = types.listOf types.path;
      default = [ ];
      example = literalExample "[ pkgs.dejavu_fonts ]";
      description = "List of primary font paths";
    };
  };

  config = mkIf (config.fonts.fonts != []) {
    home.file.".local/share/fonts".source = pkgs.symlinkJoin {
      name = "fonts";
      paths = [ config.fonts.fonts ];
    };
  };
}
