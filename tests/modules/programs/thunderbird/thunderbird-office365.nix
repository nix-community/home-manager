{
  config,
  pkgs,
  ...
}:
let
  defaultAccountId = builtins.hashString "sha256" "default@example.com";
  overriddenAccountId = builtins.hashString "sha256" "overridden@example.com";
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  profilesDir = if isDarwin then "Library/Thunderbird/Profiles" else ".thunderbird";
  userJs = "home-files/${profilesDir}/default/user.js";
in
{
  accounts.email.accounts."default@example.com" = {
    address = "default@example.com";
    flavor = "outlook.office365.com";
    primary = true;
    realName = "Default Office365";
    thunderbird.enable = true;
  };

  accounts.email.accounts."overridden@example.com" = {
    address = "overridden@example.com";
    flavor = "outlook.office365.com";
    realName = "Overridden Office365";
    imap.authentication = "ntlm";
    smtp.authentication = "clear";
    thunderbird.enable = true;
  };

  programs.thunderbird = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "thunderbird";
    };

    profiles.default.isDefault = true;
  };

  nmt.script = ''
    assertFileContains ${userJs} 'user_pref("mail.server.server_${defaultAccountId}.authMethod", 10);'
    assertFileContains ${userJs} 'user_pref("mail.smtpserver.smtp_${defaultAccountId}.authMethod", 10);'
    assertFileContains ${userJs} 'user_pref("mail.server.server_${defaultAccountId}.socketType", 3);'

    assertFileContains ${userJs} 'user_pref("mail.server.server_${overriddenAccountId}.authMethod", 6);'
    assertFileContains ${userJs} 'user_pref("mail.smtpserver.smtp_${overriddenAccountId}.authMethod", 3);'
  '';
}
