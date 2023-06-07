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
      {
        merged = dag.entryBefore [ "between" ] "middle";
      }

      # Some tests of list entries.
      (dag.entriesAnywhere "list-anywhere" [
        "list-anywhere-0"
        "list-anywhere-1"
        "list-anywhere-2"
      ])
      { inside-list = dag.entryAfter [ "list-anywhere-1" ] "inside-list"; }
      (dag.entriesBefore "list-before" [ "list-anywhere-1" ] [
        "list-before-0"
        "list-before-1"
      ])
      (dag.entriesAfter "list-after" [ "list-before-0" ] [
        "list-after-0"
        "list-after-1"
      ])
      (dag.entriesAnywhere "list-empty" [ ])
      { "list-before-0" = mkAfter "sneaky-merge"; }
    ];

    home.file."result.txt".text = result;

    nmt.script = ''
      assertFileContent \
        home-files/result.txt \
        ${./dag-merge-result.txt}
    '';
  };
}
