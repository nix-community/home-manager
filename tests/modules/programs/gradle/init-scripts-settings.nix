{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.gradle = {
      enable = true;

      initScripts = {
        "inline-init-script.gradle".text = ''
          println 'inline-init-script'
        '';
        "external-init-script.gradle".source = ./external-init-script.gradle;
      };
    };

    programs.java.package =
      pkgs.runCommandLocal "java" { home = ""; } "mkdir $out";

    test.stubs.gradle = { };

    nmt.script = ''
      assertFileExists home-files/.gradle/init.d/inline-init-script.gradle
      assertFileContent home-files/.gradle/init.d/inline-init-script.gradle ${
        pkgs.writeText "gradle.expected" ''
          println 'inline-init-script'
        ''
      }

      assertFileExists home-files/.gradle/init.d/external-init-script.gradle
      assertFileContent home-files/.gradle/init.d/external-init-script.gradle ${
        ./external-init-script.gradle
      }
    '';
  };
}
