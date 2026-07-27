{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.home) profileDirectory;
in
{
  # macOS has no systemd/environment.d equivalent, so expose Home Manager's
  # terminfo via the shell session file sourced by bash/zsh.
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    # Not using `home.sessionSearchVariables` because it only prepends, whereas
    # we need `/usr/share/terminfo` appended as an explicit fallback: once
    # TERMINFO_DIRS is set, ncurses stops searching the default system path.
    #
    # The value must not reference TERMINFO_DIRS itself: plain session
    # variables are re-exported every time `hm-session-vars.sh` is sourced, so
    # a self-referential value would grow in nested shells. A TERMINFO_DIRS
    # already set outside Home Manager is therefore replaced rather than
    # extended; set this option explicitly to keep such a value.
    home.sessionVariables.TERMINFO_DIRS = lib.mkDefault "${profileDirectory}/share/terminfo:/usr/share/terminfo";

    home.sessionVariablesExtra = ''
      # reset TERM with new TERMINFO available (if any)
      export TERM="$TERM"
    '';
  };
}
