{ config, lib, pkgs, ... }:

with lib;

let
  credentials = [
    {
      realm = "Sonatype Nexus Repository Manager";
      host = "example.com";
      user = "user";
      passwordCommand = "echo password";
    }
    {
      realm = "Sonatype Nexus Repository Manager X";
      host = "v2.example.com";
      user = "user1";
      passwordCommand = "echo password1";
    }
  ];
  expectedCredentialsSbt = pkgs.writeText "credentials.sbt" ''
    import scala.sys.process._
    credentials += Credentials("Sonatype Nexus Repository Manager", "example.com", "user", "echo password".lazyLines.mkString("\n"))
    credentials += Credentials("Sonatype Nexus Repository Manager X", "v2.example.com", "user1", "echo password1".lazyLines.mkString("\n"))
  '';
  credentialsSbtPath = ".sbt/1.0/credentials.sbt";
in {
  config = {
    programs.sbt = {
      enable = true;
      credentials = credentials;
      package = pkgs.writeScriptBin "sbt" "";
    };

    nmt.script = ''
      assertFileExists "home-files/${credentialsSbtPath}"
      assertFileContent "home-files/${credentialsSbtPath}" "${expectedCredentialsSbt}"
    '';
  };
}
