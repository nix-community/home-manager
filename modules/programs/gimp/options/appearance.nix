{ lib, ... }:
let
  inherit (lib) literalExpression mkOption types;
in
{
  options.programs.gimp = {
    themes = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''{ "MyDark" = ./my-dark-theme; }'';
      description = ''
        GTK theme directories installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/themes/<name>/`.
        Each value must be a directory containing at minimum `gtk-3.0/gtk.css`.
        Select in GIMP under **Edit → Preferences → Interface → Theme**.
      '';
    };

    icons = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''{ "Papirus" = "''${pkgs.papirus-icon-theme}/share/icons/Papirus"; }'';
      description = ''
        Icon theme directories installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/icons/<name>/`.
        Each value must be a directory containing an `index.theme` file.
        Select in GIMP under **Edit → Preferences → Interface → Icon Theme**.
      '';
    };
  };
}
