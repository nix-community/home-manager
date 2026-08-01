{
  programs.pnpm.enable = true;

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh

    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      'export PATH="/home/hm-user/.local/share/pnpm/bin''${PATH:+:}$PATH"'
    assertFileNotRegex $hmSessVars '^export PNPM_HOME='
  '';
}
