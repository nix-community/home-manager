{ pkgs, ... }:
{
  time = "2026-06-20T21:13:28+00:00";
  condition = pkgs.stdenv.isDarwin;
  message = ''
    A new module option is avaliable: 'targets.darwin.defaults."com.apple.dock".persistant-apps' and 'targets.darwin.defaults."com.apple.dock".persistant-others'.

    This is an implementation for declaritvely setting the finder dock on MacOS similar to nix-darwin.
  '';
}
