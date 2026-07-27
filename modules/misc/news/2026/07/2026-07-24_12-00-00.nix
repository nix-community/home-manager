{
  time = "2026-07-24T12:00:00+00:00";
  condition = true;
  message = ''
    The generated `hm-session-vars.sh` file is now safe to source multiple
    times, and Bash, Zsh and Fish re-source it on startup.

    Plain `home.sessionVariables` are no longer guarded by
    `__HM_SESS_VARS_SOURCED`, so newly started shells pick up changed values
    after `home-manager switch` without logging out. Zsh sources the file from
    `.zshenv` and Fish from `config.fish`, so those shells receive the current
    values also under a terminal multiplexer such as tmux. Bash sources it
    from `.profile`, so Bash picks up changed values in newly started login
    shells.

    Non-empty entries from `home.sessionPath` and
    `home.sessionSearchVariables` are now only prepended when they are not
    already present in the variable. Duplicate entries contributed by merged
    Home Manager modules are added once. This avoids adding another copy when
    the guard variable is lost while the modified values are kept. An entry
    that is already present keeps its current position and is no longer moved
    to the front, so environments that deliberately reorder `PATH` (such as
    `nix develop` or direnv) are left untouched.

    The new [](#opt-home.sessionSearchVariablesAppend) option is the
    counterpart to [](#opt-home.sessionSearchVariables): it adds entries
    behind those inherited from the environment, for trailing fallbacks such
    as a system-wide terminfo directory.

    `nix.nixPath` (when `nix.keepOldNixPath` is enabled), `xdg.systemDirs.config`
    and `xdg.systemDirs.data` now use `home.sessionSearchVariables`. The
    generated file therefore contains a prepend loop for `NIX_PATH`,
    `XDG_CONFIG_DIRS` and `XDG_DATA_DIRS` instead of a single `export`
    statement.

    Because an entry that is already present keeps its position, Home
    Manager's own relative order among its entries is not guaranteed. On
    generic Linux this changes a shipped default: `/usr/share` is normally
    inherited already, so `/var/lib/snapd/desktop` and any
    `xdg.systemDirs.data` entry now sort ahead of it in `XDG_DATA_DIRS`.

    Existing duplicates are not removed. Removing an entry from Home Manager
    configuration also does not remove it from an inherited environment; that
    requires starting with a reset environment. Systemd user services keep the
    existing `environment.d` prepend semantics and may therefore observe
    different ordering or inherited duplicates from shell sessions.

    Note that child shells now re-assert Home Manager session variable
    values: a variable exported manually in an interactive shell is reset to
    its Home Manager value in nested shells. The extra initialization added
    by modules through `home.sessionVariablesExtra` still runs only once per
    session, guarded by `__HM_SESS_VARS_SOURCED`.

    On generic Linux, Bash now reaches `nix.sh` only through this guarded
    extra section instead of sourcing it a second time from `.bashrc`. A shell
    that inherits `__HM_SESS_VARS_SOURCED` but has lost the Nix entries from
    `PATH` consequently no longer restores them; start a new session instead.

    On Darwin, `TERMINFO_DIRS` handling moved to the new
    {option}`targets.darwin.terminfo.enable` option, enabled by default. It
    keeps Home Manager's directory prepended and `/usr/share/terminfo`
    appended around anything inherited from the environment, matching the
    previous value. Two edge cases improve: the old value tripped `set -u`
    when `TERMINFO_DIRS` was unset, and appended a second
    `/usr/share/terminfo` when it was already present. Setting
    `home.sessionVariables.TERMINFO_DIRS` no longer replaces this handling; it
    now sets the base value that Home Manager extends. Set
    `targets.darwin.terminfo.enable = false` to manage the variable yourself.

    Since plain `home.sessionVariables` are re-exported every time the file is
    sourced, a value must no longer reference the variable it defines (for
    example `MANPATH = "$HOME/man:$MANPATH"`) as it would grow with every
    nested shell. Use `home.sessionPath`, `home.sessionSearchVariables` or
    `home.sessionSearchVariablesAppend` for such search paths instead.
  '';
}
