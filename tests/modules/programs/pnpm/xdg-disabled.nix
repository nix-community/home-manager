{ pkgs, ... }:

let
  expectedPnpmHome =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "/home/hm-user/Library/pnpm"
    else
      "/home/hm-user/.local/share/pnpm";
in
{
  programs.pnpm.enable = true;

  xdg = {
    enable = false;
    dataHome = "/home/hm-user/custom-data-home";
  };

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh

    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      'export PNPM_HOME="${expectedPnpmHome}"'
    (
      export PATH=/inherited/bin
      unset __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
      . "$TESTED/$hmSessVars"
      [ "$PATH" = "${expectedPnpmHome}/bin:/inherited/bin" ] \
        || { echo "PATH: $PATH"; exit 1; }
    ) || fail "pnpm bin directory was not prepended to PATH"
  '';
}
