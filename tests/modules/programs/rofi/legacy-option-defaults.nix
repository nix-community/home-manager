{ lib, ... }:
{
  imports = [ ./no-settings.nix ];
  programs.rofi.location = lib.mkOptionDefault "top";
}
