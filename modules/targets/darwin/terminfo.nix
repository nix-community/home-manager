{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.home) profileDirectory;

  cfg = config.targets.darwin.terminfo;
in
{
  options.targets.darwin.terminfo.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    example = false;
    description = ''
      Whether to expose Home Manager's terminfo database through
      {env}`TERMINFO_DIRS`.

      macOS has no {file}`environment.d` equivalent, so this goes through the
      shell session file that bash, zsh, and fish source.

      On the first merge, Home Manager prepends its own terminfo directory and
      appends {file}`/usr/share/terminfo`, keeping any inherited directories
      between the two. Later merges preserve the positions of configured
      entries already present in {env}`TERMINFO_DIRS`. The system path has to
      be appended explicitly because once {env}`TERMINFO_DIRS` is set at all,
      ncurses stops searching its built-in default.

      Set this to `false` to manage {env}`TERMINFO_DIRS` yourself. That also
      skips the {env}`TERM` re-export.
    '';
  };

  config = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && cfg.enable) {
    home.sessionSearchVariables.TERMINFO_DIRS = [ "${profileDirectory}/share/terminfo" ];

    # Place the system fallback after ordinary user-configured append entries.
    home.sessionSearchVariablesAppend.TERMINFO_DIRS = lib.mkAfter [ "/usr/share/terminfo" ];

    home.sessionVariablesExtra = ''
      # reset TERM with new TERMINFO available (if any)
      export TERM="$TERM"
    '';
  };
}
