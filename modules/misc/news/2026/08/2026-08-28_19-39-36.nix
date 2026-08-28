{ config, ... }:
{
  time = "2026-08-28T19:39:36+00:00";
  condition = config.targets.genericLinux.enable && config.programs.bash.enable;
  message = ''
    On generic Linux, Home Manager no longer sources `nix.sh` separately in
    every interactive Bash shell. The generated session variables file
    still sources it once per session tree. This prevents repeated Bash
    startup from adding duplicate `PATH` and `XDG_DATA_DIRS` entries.

    If login initialization resets `PATH` while preserving the session
    guard, Bash restores the Nix profile's `bin` directory only when it is
    missing. An existing entry keeps its position in `PATH`.

    Other values set only by `nix.sh` are not restored when a process
    preserves `__HM_SESS_VARS_SOURCED` but removes those values. If you rely
    on that behavior, restore the Nix environment at that boundary.
  '';
}
