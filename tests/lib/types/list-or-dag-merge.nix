{ config, lib, pkgs, ... }:

with lib;

let

  dag = config.lib.dag;
  hmTypes = import ../../../modules/lib/types.nix { inherit dag lib; };

  result =
    let
      sorted = dag.topoSort config.tested.dag;
      data = map (e: "${e.name}:${e.data}") sorted.result;
    in
      concatStringsSep "\n" data + "\n";

in

{
  options.tested.dag = mkOption {
    type = with types; hmTypes.listOrDagOf str;
  };

  config = {
    tested = mkMerge [
      { dag = [ "k" "l" ]; }
      { dag = [ "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" ]; }
      { dag.after = dag.entryAnywhere "after"; }
      { dag.before = dag.entryBefore ["after"] "before"; }
      { dag.between = dag.entryBetween ["after"] ["before"] "between"; }
    ];

    home.file."result.txt".text = result;

    nmt.script = ''
      assertFileContent \
        home-files/result.txt \
        ${./list-or-dag-merge-result.txt}
    '';
  };
}
