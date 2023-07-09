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

  nmt.script = let
    serviceFileName = "org.nix-community.home.imapnotify-hm-example.com.plist";
  in ''
    serviceFile="LaunchAgents/${serviceFileName}"
    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
    assertFileExists $serviceFile
    assertFileContent $serviceFileNormalized ${./launchd.plist}
  '';
}
