{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep hm mkIf mkMerge mkBefore mkAfter mkOption types;

  dag = lib.hm.dag;

  result = let
    sorted = dag.topoSort config.tested.dag;
    data = map (e: "${e.name}:${e.data}") sorted.result;
  in concatStringsSep "\n" data + "\n";

in {
  options.tested.dag = mkOption { type = hm.types.dagOf types.commas; };

  config = {
    tested.dag = mkMerge [
      (mkIf false { never = "never"; })
      { never2 = mkIf false "never2"; }
      { after = mkMerge [ "after" (mkIf false "neither") ]; }
      { before = dag.entryBefore [ "after" ] (mkIf true "before"); }
      {
        between =
          mkIf true (dag.entryBetween [ "after" ] [ "before" ] "between");
      }
      { merged = dag.entryBefore [ "between" ] "middle"; }
      { merged = mkBefore "left"; }
      { merged = dag.entryBetween [ "after" ] [ "before" ] (mkAfter "right"); }
      { merged = dag.entryBefore [ "between" ] "middle"; }
    ];

    home.file."result.txt".text = result;

    nmt.script = ''
      assertFileContent \
        home-files/result.txt \
        ${./dag-merge-result.txt}
    '';
  };
}
