{ config, ... }:

{
  time = "2026-09-01T00:00:00+00:00";
  condition = config.services.gromit-mpx.enable;
  message = ''
    The `services.gromit-mpx.extraConfig` option appends ordered CFG
    declarations after the generated tool declarations. They are written to
    the Nix store and must not contain secrets.
  '';
}
