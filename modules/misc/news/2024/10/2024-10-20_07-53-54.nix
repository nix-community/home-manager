{ pkgs, ... }:

{
  time = "2024-10-20T07:53:54+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.nh'.

    nh is yet another Nix CLI helper. Adding functionality on top of the
    existing solutions, like nixos-rebuild, home-manager cli or nix
    itself.
  '';
}
