{
  config,
  ...
}:
{
  accounts.email.accounts."hm@example.com" = {
    address = "hm@example.com";
    imap = {
      host = "imap.example.com";
      authentication = "oauthbearer";
    };
    primary = true;
    realName = "Home Manager";
    thunderbird.enable = true;
  };

  accounts.email.accounts."exchange@example.com" = {
    address = "exchange@example.com";
    ews = {
      host = "ews.example.com";
      serviceDescriptionURL = "https://ews.example.com/EWS/Exchange.asmx";
      authentication = "oauthbearer";
    };
    realName = "Exchange Account";
    thunderbird.enable = true;
  };

  accounts.email.accounts."smtp@example.com" = {
    address = "smtp@example.com";
    aliases = [
      {
        address = "inherited-alias@example.com";
        realName = "Inherited Alias";
      }
      {
        address = "overridden-alias@example.com";
        realName = "Overridden Alias";
        smtp = {
          host = "smtp-alias.example.com";
          authentication = "oauthbearer";
        };
      }
    ];
    imap.host = "imap-smtp.example.com";
    realName = "SMTP Account";
    smtp = {
      host = "smtp.example.com";
      authentication = "oauthbearer";
    };
    thunderbird.enable = true;
  };

  programs.thunderbird = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "thunderbird";
    };

    profiles.default.isDefault = true;
  };

  test.asserts.warnings.expected = [
    ''
      programs.thunderbird: accounts.email.accounts.exchange@example.com.ews uses authentication method
      'oauthbearer', which Thunderbird does not support directly. Falling back
      to password-based authentication.
    ''
    ''
      programs.thunderbird: accounts.email.accounts.hm@example.com.imap uses authentication method
      'oauthbearer', which Thunderbird does not support directly. Falling back
      to password-based authentication.
    ''
    ''
      programs.thunderbird: accounts.email.accounts.smtp@example.com.smtp uses authentication method
      'oauthbearer', which Thunderbird does not support directly. Falling back
      to password-based authentication.
    ''
    ''
      programs.thunderbird: accounts.email.accounts.smtp@example.com.aliases.overridden-alias@example.com.smtp uses authentication method
      'oauthbearer', which Thunderbird does not support directly. Falling back
      to password-based authentication.
    ''
  ];
  test.asserts.warnings.enable = true;
}
