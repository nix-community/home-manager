{ lib, ... }:

{
  options = {
    lib = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        This option allows modules to define helper functions,
        constants, etc.
      '';
    };
  };
}
