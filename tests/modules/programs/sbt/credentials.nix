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
    lazy val credential_0 = "echo password".!!.trim
    credentials += Credentials("Sonatype Nexus Repository Manager", "example.com", "user", credential_0)
    lazy val credential_1 = "echo password1".!!.trim
    credentials += Credentials("Sonatype Nexus Repository Manager X", "v2.example.com", "user1", credential_1)
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
