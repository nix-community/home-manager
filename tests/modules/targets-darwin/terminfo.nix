{
  config = {
    nmt.script = ''
      sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $sessionVarsFile
      assertFileContains $sessionVarsFile \
        'export TERMINFO_DIRS="/home/hm-user/.nix-profile/share/terminfo:$TERMINFO_DIRS''${TERMINFO_DIRS:+:}/usr/share/terminfo"'
      assertFileContains $sessionVarsFile \
        'export TERM="$TERM"'
    '';
  };
}
