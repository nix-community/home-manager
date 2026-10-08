{
  config,
  pkgs,
  ...
}:
let
  accountId = builtins.hashString "sha256" "work@example.com";
  customAccountId = builtins.hashString "sha256" "custom@example.com";
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  profilesDir = if isDarwin then "Library/Thunderbird/Profiles" else ".thunderbird";
  userJs = "home-files/${profilesDir}/default/user.js";
in
{
  accounts.email.accounts."work@example.com" = {
    address = "work@example.com";
    flavor = "outlook.office365.com-ews";
    primary = true;
    realName = "Home Manager";
    thunderbird.enable = true;
  };

  accounts.email.accounts."custom@example.com" = {
    address = "custom@example.com";
    ews = {
      host = "ews.example.com";
      serviceDescriptionURL = "https://ews.example.com/EWS/Exchange.asmx";
      authentication = "ntlm";
    };
    realName = "Custom Exchange";
    thunderbird = {
      enable = true;
      messageFilters = [
        {
          name = "Custom";
          type = "17";
          action = "Mark read";
          condition = "ALL";
        }
      ];
    };
  };

  programs.thunderbird = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "thunderbird";
    };

    profiles.default.isDefault = true;
  };

  nmt.script = ''
    assertFileContains ${userJs} 'user_pref("mail.account.account_${accountId}.server", "server_${accountId}");'
    assertFileContains ${userJs} 'user_pref("mail.smtp.defaultserver", "ews_${accountId}");'
    assertFileContains ${userJs} 'user_pref("mail.identity.id_${accountId}.smtpServer", "ews_${accountId}");'
    assertFileContains ${userJs} 'user_pref("mail.outgoingserver.ews_${accountId}.auth_method", 10);'
    assertFileContains ${userJs} 'user_pref("mail.outgoingserver.ews_${accountId}.ews_url", "https://outlook.office365.com/EWS/Exchange.asmx");'
    assertFileContains ${userJs} 'user_pref("mail.server.server_${accountId}.authMethod", 10);'
    assertFileContains ${userJs} 'user_pref("mail.server.server_${accountId}.type", "ews");'
    assertFileContains ${userJs} 'user_pref("mail.outgoingserver.ews_${customAccountId}.auth_method", 6);'
    assertFileContains ${userJs} 'user_pref("mail.outgoingserver.ews_${customAccountId}.ews_url", "https://ews.example.com/EWS/Exchange.asmx");'
    assertFileContains ${userJs} 'user_pref("mail.server.server_${customAccountId}.hostname", "ews.example.com");'
    assertFileExists home-files/${profilesDir}/default/Mail/${customAccountId}/msgFilterRules.dat
    assertFileContent \
      home-files/${profilesDir}/default/Mail/${customAccountId}/msgFilterRules.dat \
      ${pkgs.writeText "thunderbird-ews-expected-msgFilterRules.dat" ''
        version="9"
        logging="no"
        name="Custom"
        enabled="yes"
        type="17"
        action="Mark read"
        condition="ALL"
      ''}
  '';
}
