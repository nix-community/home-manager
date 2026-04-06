{ config, pkgs, ... }:
{
  time = "2026-03-25T17:18:02+00:00";
  condition = true;
  message = ''
    A new module is available: `programs.grype`

    Grype is a vulnerability scanner for container images and filesystems.
  '';
}
