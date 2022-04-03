# A generalization of Nixpkgs's `strings-with-deps.nix`.
#
# The main differences from the Nixpkgs version are
#
#  - not specific to strings, i.e., any payload is OK,
#
#  - the addition of the function `entryBefore` indicating a "wanted
#    by" relationship.

{ lib }:

let
  inherit (lib)
    all concatMapStringsSep filterAttrs head hm length mapAttrs mapAttrsToList
    tail toposort;
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

  # Given a list of entries, this function places them in order within the DAG.
  # Each entry is labeled "${tag}-${entry index}" and other DAG entries can be
  # added with 'before' or 'after' referring these indexed entries.
  #
  # The entries as a whole can be given a relation to other DAG nodes. All
  # generated nodes are then placed before or after those dependencies.
  entriesBetween = tag:
    let
      go = i: before: after: entries:
        let
          name = "${tag}-${toString i}";
          i' = i + 1;
        in if entries == [ ] then
          hm.dag.empty
        else if length entries == 1 then {
          "${name}" = hm.dag.entryBetween before after (head entries);
        } else
          {
            "${name}" = hm.dag.entryAfter after (head entries);
          } // go (i + 1) before [ name ] (tail entries);
    in go 0;

  entriesAnywhere = tag: hm.dag.entriesBetween tag [ ] [ ];
  entriesAfter = tag: hm.dag.entriesBetween tag [ ];
  entriesBefore = tag: before: hm.dag.entriesBetween tag before [ ];

  # Converts `value` and its descendants (if `value` is a list or set)
  # to JSON, maintaining the order of any DAGs encountered instead of
  # treating them as sets. `depth` controls the number of levels to
  # convert while being mindful of DAGs before literally converting
  # elements or values encountered. To convert `value` and all its
  # descendants appearing to be DAGs to ordered JSON objects, specify
  # a null `depth`. To only convert `value` to an ordered JSON object
  # (if it is a DAG) and treat none of its descendants (if it is a
  # list or a set) as DAGs, specify a `depth` of `1`.
  #
  # Example:
  #    nix-repl> toJson 1 {
  #                a = entryAnywhere "1";
  #                b = entryAfter [ "a" "c" ] "2";
  #                c = entryBefore [ "d" ] "3";
  #                d = entryBefore [ "e" ] "4";
  #                e = entryAnywhere {
  #                  f = {
  #                    after = [ "x" ];
  #                    before = [ "y" ];
  #                    data = "z";
  #                  };
  #                };
  #              }
  #    ''{"a":"1","c":"3","b":"2","d":"4","e":{"f":{"after":["x"],"before":["y"],"data":"z"}}}''
  #
  # Note: If `depth` were null or greater than `1` in the example
  # above, the attribute `e` would have been identified as a DAG
  # (because its attribute `f` resembles a DAG entry) and thus
  # converted to an ordered JSON object.
  toJson = depth: value:
    if depth == null || depth > 0 then
      let nextDepth = if depth == null then null else depth - 1;
      in (if hm.dag.isDag value then
        "{" + (concatMapStringsSep "," ({ name, data }:
          "${builtins.toJSON name}:${hm.dag.toJson nextDepth data}")
          (hm.dag.topoSort value).result) + "}"
      else if builtins.isAttrs value then
        "{" + (builtins.concatStringsSep "," (mapAttrsToList (name: value:
          "${builtins.toJSON name}:${hm.dag.toJson nextDepth value}") value))
        + "}"
      else if builtins.isList value then
        "[" + (concatMapStringsSep "," (hm.dag.toJson nextDepth) value) + "]"
      else
        builtins.toJSON value)
    else
      builtins.toJSON value;
}
