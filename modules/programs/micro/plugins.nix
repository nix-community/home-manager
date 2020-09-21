lib:
lib.mkOption {
  type = lib.types.listOf lib.types.str;
  default = [ ];
  example = [
    "autoclose"
    "comment"
    "diff"
    "ftoptions"
    "initlua"
    "linter"
    "literate"
    "status"
  ];
  description = ''
    List of plugins to enable.
  '';
}
