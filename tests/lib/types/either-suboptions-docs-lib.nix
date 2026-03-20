{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption;

  docs = import ../../../docs {
    inherit pkgs lib;
    inherit (config.home.version) release isReleaseBranch;
  };

  inherit (docs._internal.docsLib) types;

  scalarOrSubmodule = types.either types.str (
    types.submodule {
      options = {
        foo = mkOption { type = types.str; };
        bar = mkOption { type = types.int; };
      };
    }
  );

  scalarOrSubmoduleSubOptions = scalarOrSubmodule.getSubOptions [ ];
  nullOrScalarOrSubmoduleSubOptions = (types.nullOr scalarOrSubmodule).getSubOptions [ ];
in
{
  assertions = [
    {
      assertion = scalarOrSubmoduleSubOptions ? foo;
      message = "docsLib.types.either should expose submodule options when one side is scalar.";
    }
    {
      assertion = scalarOrSubmoduleSubOptions ? bar;
      message = "docsLib.types.either should expose all submodule options when one side is scalar.";
    }
    {
      assertion = nullOrScalarOrSubmoduleSubOptions ? foo;
      message = "docsLib.types.nullOr (types.either ...) should keep submodule options visible.";
    }
    {
      assertion = nullOrScalarOrSubmoduleSubOptions ? bar;
      message = "docsLib.types.nullOr (types.either ...) should keep all submodule options visible.";
    }
  ];
}
