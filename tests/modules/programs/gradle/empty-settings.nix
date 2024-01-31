{ pkgs, ... }:

{
  config = {
    programs.gradle.enable = true;

    programs.java.package =
      pkgs.runCommandLocal "java" { home = ""; } "mkdir $out";

    test.stubs.gradle = { };

    nmt.script = ''
      assertPathNotExists home-files/.gradle
      assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'GRADLE_USER_HOME'
    '';
  };
}
