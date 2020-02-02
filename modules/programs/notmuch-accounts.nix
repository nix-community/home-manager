{ lib, ... }:

{
  options.notmuch = { enable = lib.mkEnableOption "notmuch indexing"; };
}
