{ lib, ... }:

{
  meta.maintainers = with lib.maintainers; [ midchildan ];

  imports = [
    ./user-defaults
    ./fonts.nix
    ./keybindings.nix
    ./linkapps.nix
    ./search.nix
  ];
}
