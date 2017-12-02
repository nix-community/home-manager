{ lib }:

{
  dag =
    let
      d = import ./dag.nix { inherit lib; };
    in
      {
        empty = d.emptyDag;
        isDag = d.isDag;
        topoSort = d.dagTopoSort;
        map = d.dagMap;
        entryAnywhere = d.dagEntryAnywhere;
        entryBetween = d.dagEntryBetween;
        entryAfter = d.dagEntryAfter;
        entryBefore = d.dagEntryBefore;
      };
}
