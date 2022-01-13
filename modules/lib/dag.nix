# A generalization of Nixpkgs's `strings-with-deps.nix`.
#
# The main differences from the Nixpkgs version are
#
#  - not specific to strings, i.e., any payload is OK,
#
#  - the addition of the function `entryBefore` indicating a "wanted
#    by" relationship.

{ lib }:

let inherit (lib) all filterAttrs hm mapAttrs toposort;
in {
  empty = { };

  isEntry = e: e ? data && e ? after && e ? before;
  isDag = dag:
    builtins.isAttrs dag && all hm.dag.isEntry (builtins.attrValues dag);

  # Takes an attribute set containing entries built by entryAnywhere,
  # entryAfter, and entryBefore to a topologically sorted list of
  # entries.
  #
  # Internally this function uses the `toposort` function in
  # `<nixpkgs/lib/lists.nix>` and its value is accordingly.
  #
  # Specifically, the result on success is
  #
  #    { result = [ { name = ?; data = ?; } … ] }
  #
  # For example
  #
  #    nix-repl> topoSort {
  #                a = entryAnywhere "1";
  #                b = entryAfter [ "a" "c" ] "2";
  #                c = entryBefore [ "d" ] "3";
  #                d = entryBefore [ "e" ] "4";
  #                e = entryAnywhere "5";
  #              } == {
  #                result = [
  #                  { data = "1"; name = "a"; }
  #                  { data = "3"; name = "c"; }
  #                  { data = "2"; name = "b"; }
  #                  { data = "4"; name = "d"; }
  #                  { data = "5"; name = "e"; }
  #                ];
  #              }
  #    true
  #
  # And the result on error is
  #
  #    {
  #      cycle = [ { after = ?; name = ?; data = ? } … ];
  #      loops = [ { after = ?; name = ?; data = ? } … ];
  #    }
  #
  # For example
  #
  #    nix-repl> topoSort {
  #                a = entryAnywhere "1";
  #                b = entryAfter [ "a" "c" ] "2";
  #                c = entryAfter [ "d" ] "3";
  #                d = entryAfter [ "b" ] "4";
  #                e = entryAnywhere "5";
  #              } == {
  #                cycle = [
  #                  { after = [ "a" "c" ]; data = "2"; name = "b"; }
  #                  { after = [ "d" ]; data = "3"; name = "c"; }
  #                  { after = [ "b" ]; data = "4"; name = "d"; }
  #                ];
  #                loops = [
  #                  { after = [ "a" "c" ]; data = "2"; name = "b"; }
  #                ];
  #              }
  #    true
  topoSort = dag:
    let
      dagBefore = dag: name:
        builtins.attrNames
        (filterAttrs (n: v: builtins.elem name v.before) dag);
      normalizedDag = mapAttrs (n: v: {
        name = n;
        data = v.data;
        after = v.after ++ dagBefore dag n;
      }) dag;
      before = a: b: builtins.elem a.name b.after;
      sorted = toposort before (builtins.attrValues normalizedDag);
    in if sorted ? result then {
      result = map (v: { inherit (v) name data; }) sorted.result;
    } else
      sorted;

  # Applies a function to each element of the given DAG.
  map = f: mapAttrs (n: v: v // { data = f n v.data; });

  entryBetween = before: after: data: { inherit data before after; };

  # Create a DAG entry with no particular dependency information.
  entryAnywhere = hm.dag.entryBetween [ ] [ ];

  entryAfter = hm.dag.entryBetween [ ];
  entryBefore = before: hm.dag.entryBetween before [ ];
}
