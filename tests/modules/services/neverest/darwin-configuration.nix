{ config, ... }:
{
  imports = [ ../../accounts/email-test-accounts.nix ];

  home.enableNixpkgsReleaseCheck = false;

  accounts.email.accounts."hm@example.com" = {
    maildir.path = "hm-example.com";
    neverest.enable = true;
  };

  programs.neverest = {
    package = config.lib.test.mkStubPackage {
      name = "neverest";
      outPath = "@neverest@";
    };
  };

  services.neverest = {
    enable = true;
    frequency = "hourly";
  };

  nmt.script =
    let
      plistFileName = "org.nix-community.home.neverest.plist";
    in
    ''
      serviceFile="LaunchAgents/${plistFileName}"
      serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
      assertFileExists "$serviceFile"
      assertFileContent "$serviceFileNormalized" ${./neverest.plist}
    '';
}
