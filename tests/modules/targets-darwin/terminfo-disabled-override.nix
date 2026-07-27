{ lib, ... }:

{
  # A definition that is conditionally disabled must not suppress the default;
  # the module system, not an attribute existence check, decides the value.
  home.sessionVariables.TERMINFO_DIRS = lib.mkIf false "/custom/terminfo";

  nmt.script = ''
    sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $sessionVarsFile
    assertFileContains $sessionVarsFile \
      'export TERMINFO_DIRS="/home/hm-user/.nix-profile/share/terminfo:/usr/share/terminfo"'
    assertFileNotRegex $sessionVarsFile '/custom/terminfo'
  '';
}
