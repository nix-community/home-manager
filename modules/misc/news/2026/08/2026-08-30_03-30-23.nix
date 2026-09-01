{ config, ... }:

{
  time = "2026-08-30T03:30:23+00:00";
  condition = config.programs.carapace.enable;
  message = ''
    Carapace can now be configured with the
    `programs.carapace.environment` and `programs.carapace.extraPackages`
    options. The `programs.carapace.ignoreCase` option has been renamed to
    `programs.carapace.environment.CARAPACE_MATCH`.
  '';
}
