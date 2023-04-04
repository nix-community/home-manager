{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      thunderbird = {
        enable = true;
        profiles = [ "first" ];
      };

      gpg.key = "ABC";

      imap = {
        port = 123;
        tls.enable = true;
      };
      smtp.port = 456;
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

      second.settings = { "second.setting" = "some-test-setting"; };
    };

    settings = {
      "general.useragent.override" = "";
      "privacy.donottrackheader.enabled" = true;
    };
  };

  test.stubs.thunderbird = { };

  nmt.script = ''
    assertFileExists home-files/.thunderbird/profiles.ini
    assertFileContent home-files/.thunderbird/profiles.ini \
      ${./thunderbird-expected-profiles.ini}

    assertFileExists home-files/.thunderbird/first/user.js
    assertFileContent home-files/.thunderbird/first/user.js \
      ${./thunderbird-expected-first.js}

    assertFileExists home-files/.thunderbird/second/user.js
    assertFileContent home-files/.thunderbird/second/user.js \
      ${./thunderbird-expected-second.js}

    assertFileExists home-files/.thunderbird/first/chrome/userChrome.css
    assertFileContent home-files/.thunderbird/first/chrome/userChrome.css \
      <(echo "* { color: blue !important; }")

    assertFileExists home-files/.thunderbird/first/chrome/userContent.css
    assertFileContent home-files/.thunderbird/first/chrome/userContent.css \
      <(echo "* { color: red !important; }")
  '';
}
