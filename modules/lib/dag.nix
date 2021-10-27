# A generalization of Nixpkgs's `strings-with-deps.nix`.
#
# The main differences from the Nixpkgs version are
#
#  - not specific to strings, i.e., any payload is OK,
#
#  - the addition of the function `dagEntryBefore` indicating a
#    "wanted by" relationship.

{ lib }:

let inherit (lib) all any filterAttrs mapAttrs mapAttrsToList toposort;
in rec {

  emptyDag = { };

  isDag = dag:
    let isEntry = e: (e ? data) && (e ? after) && (e ? before);
    in builtins.isAttrs dag && all (x: x) (mapAttrsToList (n: isEntry) dag);

  # Takes an attribute set containing entries built by
  # dagEntryAnywhere, dagEntryAfter, and dagEntryBefore to a
  # topologically sorted list of entries.
  #
  # Internally this function uses the `toposort` function in
  # `<nixpkgs/lib/lists.nix>` and its value is accordingly.
  #
  # Specifically, the result on success is
  #
  #    { result = [{name = ?; data = ?;} …] }
  #
  # For example
  #
  #    nix-repl> dagTopoSort {
  #                a = dagEntryAnywhere "1";
  #                b = dagEntryAfter ["a" "c"] "2";
  #                c = dagEntryBefore ["d"] "3";
  #                d = dagEntryBefore ["e"] "4";
  #                e = dagEntryAnywhere "5";
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
  #      cycle = [ {after = ?; name = ?; data = ?} … ];
  #      loops = [ {after = ?; name = ?; data = ?} … ];
  #    }
  #
  # For example
  #
  #    nix-repl> dagTopoSort {
  #                a = dagEntryAnywhere "1";
  #                b = dagEntryAfter ["a" "c"] "2";
  #                c = dagEntryAfter ["d"] "3";
  #                d = dagEntryAfter ["b"] "4";
  #                e = dagEntryAnywhere "5";
  #              } == {
  #                cycle = [
  #                  { after = ["a" "c"]; data = "2"; name = "b"; }
  #                  { after = ["d"]; data = "3"; name = "c"; }
  #                  { after = ["b"]; data = "4"; name = "d"; }
  #                ];
  #                loops = [
  #                  { after = ["a" "c"]; data = "2"; name = "b"; }
  #                ];
  #              } == {}
  #    true
  dagTopoSort = dag:
    let
      dagBefore = dag: name:
        mapAttrsToList (n: v: n)
        (filterAttrs (n: v: any (a: a == name) v.before) dag);
      normalizedDag = mapAttrs (n: v: {
        name = n;
        data = v.data;
        after = v.after ++ dagBefore dag n;
      }) dag;
      before = a: b: any (c: a.name == c) b.after;
      sorted = toposort before (mapAttrsToList (n: v: v) normalizedDag);
    in if sorted ? result then {
      result = map (v: { inherit (v) name data; }) sorted.result;
    } else
      sorted;

  # Applies a function to each element of the given DAG.
  dagMap = f: dag: mapAttrs (n: v: v // { data = f n v.data; }) dag;

  # Create a DAG entry with no particular dependency information.
  dagEntryAnywhere = data: {
    inherit data;
    before = [ ];
    after = [ ];
  };

  dagEntryBetween = before: after: data: { inherit data before after; };

  dagEntryAfter = after: data: {
    inherit data after;
    before = [ ];
  };

  dagEntryBefore = before: data: {
    inherit data before;
    after = [ ];
  };

}
