{ config, lib, pkgs, ... }:

let
  inherit (lib) concatStringsSep hm mkOption types;

  dag = lib.hm.dag;

  result = let
    sorted = dag.topoSort config.tested.dag;
    data = map (e: "${e.name}:${e.data.name}") sorted.result;
  in concatStringsSep "\n" data + "\n";

in {
  options.tested.dag = mkOption {
    type = hm.types.dagOf (types.submodule ({ dagName, ... }: {
      options.name = mkOption { type = types.str; };
      config.name = "dn-${dagName}";
    }));
  };

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
        ${
          pkgs.writeText "result.txt" ''
            before:dn-before
            between:dn-between
            after:dn-after
          ''
        }
    '';
  };
}
