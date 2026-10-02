{ config, ... }:
{
  time = "2026-09-10T12:00:00+00:00";
  condition = config.targets.genericLinux.enable;
  message = ''
    Generic Linux shell startup now restores the standard Nix profile
    environment when a parent login environment removes it. The refresh keeps
    existing search-path positions, explicit scalar values, and empty scalar
    overrides. It covers the standard Nix profile script variables; additional
    side effects from custom `nix.package` profile scripts are not reproduced.
  '';
}
