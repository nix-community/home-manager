{ lib, pkgs, ... }:

{
  dbeaver-without-settings = ./without-settings.nix;
  dbeaver-with-settings = ./with-settings.nix;
  dbeaver-with-data-sources = ./with-data-sources.nix;
}
