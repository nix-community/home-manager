{ pkgs, ... }:
{
  time = "2026-09-03T15:51:16+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available `services.hyprscratch`.

    Hyprscratch makes scratchpads in Hyprland painless in a well-integrated and
    flexible way.

    See <https://github.com/sashetophizika/hyprscratch> for more details.
  '';
}
