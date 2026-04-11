{ config, pkgs, ... }:
{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts."hm@example.com" = {
    maildir.path = "hm-example.com";
    imapgoose.enable = true;
  };

  programs.imapgoose = {
    package = config.lib.test.mkStubPackage {
      name = "imapgoose";
      outPath = "@imapgoose@";
    };
  };

  services.imapgoose = {
    enable = true;
    frequency = "hourly";
  };

  nmt.script =
    let
      plistFileName = "org.nix-community.home.imapgoose.plist";
    in
    ''
      serviceFile="LaunchAgents/${plistFileName}"
      serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
      assertFileExists "$serviceFile"
      assertFileContent "$serviceFileNormalized" ${./imapgoose.plist}
    '';
}
