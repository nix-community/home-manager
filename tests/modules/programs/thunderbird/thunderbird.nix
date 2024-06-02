{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../accounts/email-test-accounts.nix
  ];

  accounts.email.accounts = {
    "hm@example.com" = {
      thunderbird = {
        enable = true;
        profiles = [ "first" ];
        messageFilters = [
          {
            name = "Should be first";
            enabled = true;
            type = "128";
            action = "Cry";
            condition = "ALL";
          }
          {
            name = "Mark as Read on Archive";
            enabled = true;
            type = "128";
            action = "Mark read";
            condition = "ALL";
          }
        ];
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

  accounts.calendar.accounts = {
    calendar = {
      thunderbird = {
        enable = true;
        profiles = [ "first" ];
      };
      primary = true;
      remote = {
        type = "caldav";
        url = "https://my.caldav.server/calendar";
        userName = "testuser";
      };
    };
    holidays = {
      thunderbird = {
        enable = true;
        readOnly = true;
      };
      remote = {
        type = "http";
        url = "https://www.thunderbird.net/media/caldata/autogen/GermanHolidays.ics";
      };
    };
    local = {
      thunderbird = {
        enable = true;
        profiles = [ "second" ];
      };
    };
  };

  programs.thunderbird = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "thunderbird";
    };

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

        accountsOrder = [
          "hm@example.com"
          "rss"
          "imperative_account"
          "hm-account"
        ];
        calendarAccountsOrder = [
          "calendar"
          "imperative_cal"
          "holidays"
        ];
      };

      second = {
        settings = {
          "second.setting" = "some-test-setting";
          second.nested.evenFurtherNested = [
            1
            2
            3
          ];
        };
        accountsOrder = [ "account1" ];
        calendarAccountsOrder = [ "calendar1" ];
      };
    };

    settings = {
      "general.useragent.override" = "";
      "privacy.donottrackheader.enabled" = true;
    };
  };

  nmt.script =
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      configDir = if isDarwin then "Library/Thunderbird" else ".thunderbird";
      profilesDir = if isDarwin then "${configDir}/Profiles" else "${configDir}";
      platform = if isDarwin then "darwin" else "linux";
    in
    ''
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

      assertFileExists home-files/${profilesDir}/first/ImapMail/${builtins.hashString "sha256" "hm@example.com"}/msgFilterRules.dat
      assertFileContent home-files/${profilesDir}/first/ImapMail/${builtins.hashString "sha256" "hm@example.com"}/msgFilterRules.dat \
        ${./thunderbird-expected-msgFilterRules.dat}
    '';
}
