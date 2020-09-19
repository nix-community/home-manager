lib:
lib.mkOption {
  type = lib.types.attrsOf lib.types.str;
  default = { };
  example = {
    "Alt-/" = "lua:comment.comment";
    "CtrlUnderscore" = "lua:comment.comment";
  };
  description = ''
    Rebind keys and key combinations to certain actions.
    See [here](https://github.com/zyedidia/micro/blob/master/runtime/help/keybindings.md) for further information.
  '';
}
