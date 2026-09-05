{
  programs.pnpm = {
    enable = true;
    homeDir = "/home/hm-user/.pnpm";
  };

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh

    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      'export PNPM_HOME="/home/hm-user/.pnpm"'
    assertFileContains $hmSessVars \
      'export PATH="/home/hm-user/.pnpm/bin''${PATH:+:}$PATH"'
  '';
}
