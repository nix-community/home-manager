{ config, ... }:
{
  time = "2025-08-01T14:53:46+00:00";
  condition = config.programs.tmux.enable;
  message = ''
    The 'programs.tmux' module has improved prefix key configuration.

    Custom prefix key settings now properly register and function correctly.
    If you previously had issues with custom prefix keys not working,
    they should now function as expected.
  '';
}
