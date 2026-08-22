{ pkgs, ... }:

let
  expectedHomeDir =
    if pkgs.stdenv.isDarwin then "/home/hm-user/Library/pnpm" else "/home/hm-user/.local/share/pnpm";
in
{
  programs.pnpm.enable = true;

  xdg.enable = false;

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh

    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      'export PATH="${expectedHomeDir}/bin''${PATH:+:}$PATH"'
    assertFileNotRegex $hmSessVars '^export PNPM_HOME='
  '';
}
