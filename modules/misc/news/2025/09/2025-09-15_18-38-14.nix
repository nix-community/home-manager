{ config, ... }:
{
  time = "2025-09-15T22:38:14+00:00";
  condition = config.programs.floorp.enable;
  message = ''
    `programs.floorp` now uses `pkgs.floorp-bin` by default,
    as `pkgs.floorp` was removed from nixpkgs.
  '';
}
