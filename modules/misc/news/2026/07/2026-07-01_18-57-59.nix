{ config, ... }:
{
  time = "2026-07-01T23:57:59+00:00";
  condition =
    config.programs.atuin.enable
    && config.programs.atuin.enableNushellIntegration
    && config.programs.nushell.enable;
  message = ''
    Home Manager now loads the Atuin Nushell integration after other shell
    integrations such as fzf. This restores Atuin's Ctrl-R binding when both
    programs are enabled.

    If you previously used `programs.nushell.extraConfig = lib.mkAfter ...`
    to place custom Nushell configuration after Atuin, use a later order such
    as `lib.mkOrder 2001 ...` instead.
  '';
}
