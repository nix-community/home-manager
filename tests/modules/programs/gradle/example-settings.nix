{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.gradle = {
      enable = true;
      settings = {
        "org.gradle.caching" = true;
        "org.gradle.parallel" = true;
        "org.gradle.java.home" = pkgs.jdk17;
        "org.gradle.java.installations.paths" = "${pkgs.jdk8},${pkgs.jdk11}";
      };
    };

    programs.java.package =
      pkgs.runCommandLocal "java" { home = ""; } "mkdir $out";

    test.stubs = {
      gradle = { };
      jdk = { };
      jdk8 = { };
      jdk11 = { };
      jdk17 = { };
    };

    nmt.script = ''
      assertFileExists home-files/.gradle/gradle.properties
      assertFileContent home-files/.gradle/gradle.properties ${
        builtins.toFile "gradle.expected" ''
          # Generated with Nix

          org.gradle.caching = true
          org.gradle.java.home = @jdk17@
          org.gradle.java.installations.paths = @jdk8@,@jdk11@
          org.gradle.parallel = true
        ''
      }
    '';
  };
}
