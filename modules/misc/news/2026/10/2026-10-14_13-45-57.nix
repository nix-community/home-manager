{ config, ... }:
let
  cfg = config.programs.fzf;
in
{
  time = "2026-10-14T18:45:57+00:00";
  condition =
    cfg.enable
    && (
      (config.programs.bash.enable && cfg.enableBashIntegration)
      || (config.programs.fish.enable && cfg.enableFishIntegration)
      || (config.programs.nushell.enable && cfg.enableNushellIntegration)
      || (config.programs.zsh.enable && cfg.enableZshIntegration)
    );
  message = ''
    fzf shell integrations now load scripts from `programs.fzf.package`
    instead of running fzf to generate them.

    Custom packages must include the integration scripts under `share/fzf`
    for the enabled shells. If you wrap fzf, preserve that directory alongside
    the executable, or use the default package. The default package already
    includes these files and needs no configuration change.
  '';
}
