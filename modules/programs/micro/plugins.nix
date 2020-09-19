let
  plugins = [
    "autoclose"
    "comment"
    "diff"
    "ftoptions"
    "initlua"
    "linter"
    "literate"
    "status"
  ];
in lib:
lib.mkOption {
  type = lib.types.listOf (lib.types.enum plugins);
  default = [ ];
  example = plugins;
  description = ''
    List of plugins to enable.
  '';
}
