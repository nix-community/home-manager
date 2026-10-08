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
    home.sessionVariables = {
      TERMINFO_DIRS = lib.mkDefault "${profileDirectory}/share/terminfo:$TERMINFO_DIRS\${TERMINFO_DIRS:+:}/usr/share/terminfo";
    };

    home.sessionVariablesExtra = ''
      # reset TERM with new TERMINFO available (if any)
      export TERM="$TERM"
    '';
  };
}
