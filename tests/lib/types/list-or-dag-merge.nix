{ config, lib, pkgs, ... }:

let
  inherit (lib) concatStringsSep hm mkMerge mkOption types;

  dag = lib.hm.dag;

  result = let
    sorted = dag.topoSort config.tested.dag;
    data = map (e: "${e.name}:${e.data}") sorted.result;
  in concatStringsSep "\n" data + "\n";

in {
  options.tested.dag = mkOption { type = hm.types.listOrDagOf types.str; };

  config = {
    tested = mkMerge [
      { dag = [ "k" "l" ]; }
      { dag = [ "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" ]; }
      { dag.after = "after"; }
      { dag.before = dag.entryBefore [ "after" ] "before"; }
      { dag.between = dag.entryBetween [ "after" ] [ "before" ] "between"; }
    ];

    home.file."result.txt".text = result;

    nmt.script = ''
      assertFileContent \
        home-files/result.txt \
        ${./list-or-dag-merge-result.txt}
    '';
  };
}
