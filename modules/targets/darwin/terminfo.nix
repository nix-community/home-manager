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
  options.targets.darwin.terminfo.enable = lib.mkEnableOption "" // {
    default = true;
    example = false;
    description = ''
      Whether to expose Home Manager's terminfo database through
      {env}`TERMINFO_DIRS`.

      Home Manager prepends its terminfo directory and appends
      {file}`/usr/share/terminfo`, preserving inherited directories between
      them.

      Disable this to manage {env}`TERMINFO_DIRS` yourself. This also skips
      the corresponding {env}`TERM` refresh.
    '';
  };

  config = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && cfg.enable) {
    home.sessionSearchVariables.TERMINFO_DIRS = [ "${profileDirectory}/share/terminfo" ];

    # TERMINFO_DIRS disables ncurses' default path; keep the system fallback last.
    home.sessionSearchVariablesAppend.TERMINFO_DIRS = lib.mkAfter [ "/usr/share/terminfo" ];

    home.sessionVariablesExtra = ''
      # reset TERM with new TERMINFO available (if any)
      export TERM="$TERM"
    '';
  };
}
