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

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/neverest.service"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFileNormalized" ${./neverest.service}

    timerFile="home-files/.config/systemd/user/neverest.timer"
    assertFileExists "$timerFile"
    assertFileContent "$timerFile" ${./neverest.timer}
  '';
}
