{ lib }:

with lib;

rec {
  # Removes empty elements from list
  notEmpty = list: filter (x: x != "" && x != null) (flatten list);
}
