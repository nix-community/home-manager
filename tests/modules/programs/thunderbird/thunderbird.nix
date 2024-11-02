{ pkgs, ... }: {
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      thunderbird = {
        enable = true;
        profiles = [ "first" ];
      };

      aliases = [ "home-manager@example.com" ];

      gpg.key = "ABC";

      imap = {
        port = 123;
        tls.enable = true;
      };
      smtp.port = 456;

      signature = {
        text = "signature";
        showSignature = "append";
      };
    };

    hm-account = {
      thunderbird = {
        enable = true;
        settings = id: {
          "mail.identity.id_${id}.protectSubject" = false;
          "mail.identity.id_${id}.autoEncryptDrafts" = false;
        };
      };
    };
  };

  programs.thunderbird = {
    enable = true;

    # Disable warning so that platforms' behavior is the same
    darwinSetupWarning = false;

    # Darwin doesn't support wrapped Thunderbird, using unwrapped instead
    package = pkgs.thunderbird-unwrapped;

    profiles = {
      first = {
        isDefault = true;
        withExternalGnupg = true;
        userChrome = ''
          * { color: blue !important; }
        '';
        userContent = ''
          * { color: red !important; }
        '';
        extraConfig = ''
          user_pref("mail.html_compose", false);
        '';
      };

      second.settings = {
        "second.setting" = "some-test-setting";
        second.nested.evenFurtherNested = [ 1 2 3 ];
      };
    };

    nativeMessagingHosts = with pkgs;
      [
        # NOTE: this is not a real Thunderbird native host module but Firefox; no
        # native hosts are currently packaged for nixpkgs or elsewhere, so we
        # have to improvise. Packaging wise, Firefox and Thunderbird native hosts
        # are identical though. Good news is that the test will still pass as
        # long as we don't attempt to run the mail client itself with the host.
        # (Which we don't.)
        browserpass
      ];

    settings = {
      "general.useragent.override" = "";
      "privacy.donottrackheader.enabled" = true;
    };
  };

  nmt.script = let
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
    configDir = if isDarwin then "Library/Thunderbird" else ".thunderbird";
    profilesDir = if isDarwin then "${configDir}/Profiles" else "${configDir}";
    nativeHostsDir = if isDarwin then
      "Library/Mozilla/NativeMessagingHosts"
    else
      ".mozilla/native-messaging-hosts";
    platform = if isDarwin then "darwin" else "linux";
  in ''
    assertFileExists home-files/${configDir}/profiles.ini
    assertFileContent home-files/${configDir}/profiles.ini \
      ${./thunderbird-expected-profiles-${platform}.ini}

    assertFileExists home-files/${profilesDir}/first/user.js
    assertFileContent home-files/${profilesDir}/first/user.js \
      ${./thunderbird-expected-first-${platform}.js}

    assertFileExists home-files/${profilesDir}/second/user.js
    assertFileContent home-files/${profilesDir}/second/user.js \
      ${./thunderbird-expected-second-${platform}.js}

    assertFileExists home-files/${profilesDir}/first/chrome/userChrome.css
    assertFileContent home-files/${profilesDir}/first/chrome/userChrome.css \
      <(echo "* { color: blue !important; }")

    assertFileExists home-files/${profilesDir}/first/chrome/userContent.css
    assertFileContent home-files/${profilesDir}/first/chrome/userContent.css \
      <(echo "* { color: red !important; }")

    assertFileExists home-files/${nativeHostsDir}/com.github.browserpass.native.json
  '';
}
