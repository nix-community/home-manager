{ lib, realPkgs, ... }: {
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

    # Darwin doesn't support wrapped Thunderbird, using unwrapped instead;
    # using -latest- because ESR is currently broken on Darwin
    package = realPkgs.thunderbird-latest-unwrapped;

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

        feedAccounts.rss = { };
      };

      second.settings = {
        "second.setting" = "some-test-setting";
        second.nested.evenFurtherNested = [ 1 2 3 ];
      };
    };

    settings = {
      "general.useragent.override" = "";
      "privacy.donottrackheader.enabled" = true;
    };
  };

  nmt.script = let
    isDarwin = realPkgs.stdenv.hostPlatform.isDarwin;
    configDir = if isDarwin then "Library/Thunderbird" else ".thunderbird";
    profilesDir = if isDarwin then "${configDir}/Profiles" else "${configDir}";
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
  '';
}
