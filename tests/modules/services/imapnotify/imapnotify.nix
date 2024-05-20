{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      notmuch.enable = true;
      imap.port = 993;

      imapnotify = {
        enable = true;
        boxes = [ "Inbox" ];
        onNotify = ''
          ${pkgs.notmuch}/bin/notmuch new
        '';
      };
    };
  };

  services.imapnotify = {
    enable = true;
    package = (config.lib.test.mkStubPackage {
      name = "goimapnotify";
      outPath = "@goimapnotify@";
    });
  };

  test.stubs.notmuch = { };

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/imapnotify-hm-example.com.service"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
    assertFileExists $serviceFile
    assertFileContent $serviceFileNormalized ${./imapnotify.service}

    configFile="home-files/.config/imapnotify/imapnotify-hm-example.com-config.json"
    configFileNormalized="$(normalizeStorePaths "$configFile")"
    assertFileExists $configFile
    assertFileContent $configFileNormalized ${./imapnotify-config.json}
  '';
}
