{
  lib,
  ...
}:

{
  meta.maintainers = with lib.maintainers; [ midchildan ];

  imports = [
    ./fish.nix
    ./user-defaults
    ./fonts.nix
    ./keybindings.nix
    ./copyapps.nix
    ./linkapps.nix
    ./search.nix
    ./terminfo.nix
  ];
}
