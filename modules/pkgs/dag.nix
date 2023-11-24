# Converts `value` and its descendants (if `value` is a list or set)
# to a file of the specified format, maintaining the order of any DAGs
# encountered instead of treating them as sets. See
# `modules/lib/dag.nix` for an explanation of parameters.

{ lib, pkgs, ... }:

let
  dagToFile = format: name: depth: value:
    pkgs.runCommand name {
      nativeBuildInputs = [ pkgs.remarshal ];
      value = pkgs.hm.dag.toJsonFile "value.json" depth value;
    } "json2${format} --preserve-key-order $value $out";
in {
  toCborFile = dagToFile "cbor";
  toJsonFile = name: depth: value:
    pkgs.writeText name (lib.hm.dag.toJson depth value + "\n");
  toMessagePackFile = dagToFile "msgpack";
  toTomlFile = dagToFile "toml";
  toYamlFile = dagToFile "yaml";
}
