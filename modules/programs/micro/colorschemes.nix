lib:
lib.mkOption {
  type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
  default = { };
  example = { "name" = { "default" = "#F8F8F2,#282828"; }; };
  description = ''
    Define custom color scheme for micro.
    See [here](https://github.com/zyedidia/micro/blob/master/runtime/help/colors.md) for further information.
  '';
}
