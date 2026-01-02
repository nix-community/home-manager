{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    hm
    mkOption
    types
    ;

  dag = lib.hm.dag;

  result =
    let
      sorted = dag.topoSort config.tested.dag;
      data = map (e: "${e.name}:${e.data.name}:${e.data.value}") sorted.result;
    in
    concatStringsSep "\n" data + "\n";

in
{
  imports = [
    {
      options.tested.dag = mkOption {
        type = hm.types.dagOf (
          types.submodule (
            { dagName, ... }:
            {
              options.name = mkOption { type = types.str; };
              config.name = "dn-${dagName}";
            }
          )
        );
      };
    }
    {
      options.tested.dag = mkOption {
        type = hm.types.dagOf (
          types.submodule (
            { dagName, ... }:
            {
              options.value = mkOption { type = types.str; };
              config.value = "dv-${dagName}";
            }
          )
        );
      };
    }
  ];

  config = {
    tested.dag = {
      after = { };
      before = dag.entryBefore [ "after" ] { };
      between = dag.entryBetween [ "after" ] [ "before" ] { };
    };

    home.file."result.txt".text = result;

    nmt.script = ''
      assertFileContent \
        home-files/result.txt \
        ${pkgs.writeText "result.txt" ''
          before:dn-before:dv-before
          between:dn-between:dv-between
          after:dn-after:dv-after
        ''}
    '';
  };
}
