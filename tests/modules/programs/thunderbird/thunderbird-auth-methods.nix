{
  config,
  pkgs,
  ...
}:
let
  anonymousAccountId = builtins.hashString "sha256" "anonymous@example.com";
  digestAccountId = builtins.hashString "sha256" "digest@example.com";
  gssapiAccountId = builtins.hashString "sha256" "gssapi@example.com";
  mixedAccountId = builtins.hashString "sha256" "mixed@example.com";
  aliasSmtpId = builtins.hashString "sha256" "alias@example.comAlias";

  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  profilesDir = if isDarwin then "Library/Thunderbird/Profiles" else ".thunderbird";
  userJs = "home-files/${profilesDir}/default/user.js";
in
{
  accounts.email.accounts = {
    "anonymous@example.com" = {
      address = "anonymous@example.com";
      imap = {
        host = "imap-anonymous.example.com";
        authentication = "anonymous";
      };
      primary = true;
      realName = "Anonymous";
      thunderbird.enable = true;
    };

    "digest@example.com" = {
      address = "digest@example.com";
      imap = {
        host = "imap-digest.example.com";
        authentication = "digest_md5";
      };
      realName = "Digest";
      thunderbird.enable = true;
    };

    "gssapi@example.com" = {
      address = "gssapi@example.com";
      ews = {
        host = "ews-gssapi.example.com";
        serviceDescriptionURL = "https://ews-gssapi.example.com/EWS/Exchange.asmx";
        authentication = "gssapi";
      };
      realName = "GSSAPI";
      thunderbird.enable = true;
    };

    "mixed@example.com" = {
      address = "mixed@example.com";
      aliases = [
        {
          address = "alias@example.com";
          realName = "Alias";
          smtp = {
            host = "smtp-alias.example.com";
            authentication = "xoauth2";
          };
        }
      ];
      imap = {
        host = "imap-mixed.example.com";
        authentication = "ntlm";
      };
      realName = "Mixed";
      smtp = {
        host = "smtp-mixed.example.com";
        authentication = "clear";
      };
      thunderbird.enable = true;
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
    assertFileContains ${userJs} 'user_pref("mail.server.server_${anonymousAccountId}.authMethod", 1);'
    assertFileContains ${userJs} 'user_pref("mail.server.server_${digestAccountId}.authMethod", 4);'
    assertFileContains ${userJs} 'user_pref("mail.server.server_${gssapiAccountId}.authMethod", 5);'
    assertFileContains ${userJs} 'user_pref("mail.outgoingserver.ews_${gssapiAccountId}.auth_method", 5);'
    assertFileContains ${userJs} 'user_pref("mail.server.server_${mixedAccountId}.authMethod", 6);'
    assertFileContains ${userJs} 'user_pref("mail.smtpserver.smtp_${mixedAccountId}.authMethod", 3);'
    assertFileContains ${userJs} 'user_pref("mail.smtpserver.smtp_${aliasSmtpId}.authMethod", 10);'
  '';
}
