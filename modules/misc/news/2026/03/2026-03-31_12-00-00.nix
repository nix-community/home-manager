{ config, ... }:
{
  time = "2026-03-31T12:00:00+00:00";
  condition = config.programs.tmux.tmuxinator.enable;
  message = ''
    The tmuxinator integration in 'programs.tmux.tmuxinator' now supports
    declaring projects via 'programs.tmux.tmuxinator.projects'. Each
    project is written to '$HOME/.config/tmuxinator/<name>.yaml'.

    The tmuxinator package can be customised via
    'programs.tmux.tmuxinator.package'.
  '';
}
