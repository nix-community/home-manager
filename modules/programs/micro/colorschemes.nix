lib:
lib.mkOption {
  type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
  default = { };
  example = {
    "colorscheme-light" = { "default" = "italic black,white"; };
    "colorscheme-dark" = { "default" = "bold green,black"; };
  };
  description = ''
    Define custom color scheme for micro.
    See [here](https://github.com/zyedidia/micro/blob/master/runtime/help/colors.md) for further information.
  '';
}
