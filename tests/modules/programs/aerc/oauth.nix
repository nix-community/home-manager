{ config, pkgs, ... }:
{
  config = {
    nmt.script =
      let
        dir =
          if (pkgs.stdenv.isDarwin && !config.xdg.enable) then
            "home-files/Library/Preferences/aerc"
          else
            "home-files/.config/aerc";
      in
      ''
        assertFileContent ${dir}/accounts.conf ${./oauth.expected}
      '';
    programs.aerc = {
      enable = true;
      extraConfig.general.unsafe-accounts-conf = true;
    };

    accounts.email.accounts = {
      basic = {
        realName = "Annie X. Hacker";
        userName = "anniex";
        address = "anniex@mail.invalid";
        primary = true;
        flavor = "outlook.office365.com";

        aerc = rec {
          enable = true;
          imapAuth = "xoauth2";
          smtpAuth = imapAuth;
          imapOauth2Params = {
            client_id = "9e5f94bc-e8a4-4e73-b8be-63364c29d753";
            token_endpoint = "https://login.microsoftonline.com/common/oauth2/v2.0/token";
          };
          smtpOauth2Params = imapOauth2Params;
        };
      };
    };
  };
}
