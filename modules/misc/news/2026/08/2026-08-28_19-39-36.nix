{ config, ... }:
{
  time = "2026-08-28T19:39:36+00:00";
  condition = config.targets.genericLinux.enable && config.programs.bash.enable;
  message = ''
    On generic Linux, Home Manager no longer sources `nix.sh` separately in
    every interactive non-login Bash shell. The generated session variables
    file still sources it once. This prevents duplicate `PATH` and
    `XDG_DATA_DIRS` entries from accumulating in nested shells.

    A process that preserves `__HM_SESS_VARS_SOURCED` while removing values
    set only by `nix.sh` no longer has Bash restore those values. This can
    occur with customized `su` or `sudo` environment handling. Do not
    preserve the guard across a boundary that resets the Nix environment, or
    restore the Nix environment explicitly at that boundary. Normal nested
    shells and fresh sessions need no action.
  '';
}
