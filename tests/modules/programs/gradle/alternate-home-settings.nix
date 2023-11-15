{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.gradle = {
      enable = true;
      home = ".gbt";
      settings = { "org.gradle.caching" = true; };
      initScripts = { "some-script.gradle".text = "println 'hello world'"; };
    };

    programs.java.package =
      pkgs.runCommandLocal "java" { home = ""; } "mkdir $out";

    test.stubs.gradle = { };

    nmt.script = ''
      assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
        'export GRADLE_USER_HOME="/home/hm-user/.gbt"'
      assertFileExists home-files/.gbt/gradle.properties
      assertFileExists home-files/.gbt/init.d/some-script.gradle
    '';
  };
}
