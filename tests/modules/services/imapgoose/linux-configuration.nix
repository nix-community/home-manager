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

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/imapgoose.service"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFileNormalized" ${./imapgoose.service}

    timerFile="home-files/.config/systemd/user/imapgoose.timer"
    assertFileExists "$timerFile"
    assertFileContent "$timerFile" ${./imapgoose.timer}
  '';
}
