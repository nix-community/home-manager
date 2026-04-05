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
        assertFileContent ${dir}/accounts.conf ${./protocol-usernames.expected}
      '';

    programs.aerc = {
      enable = true;
      extraConfig.general.unsafe-accounts-conf = true;
    };

    accounts.email.accounts = {
      "protocol-test" = {
        primary = true;
        address = "test@example.com";
        userName = "default-user";
        realName = "Test User";
        passwordCommand = "pass test";

        imap = {
          host = "imap.example.com";
          port = 993;
          userName = "imap-specific-user";
        };

        smtp = {
          host = "smtp.example.com";
          port = 587;
          userName = "smtp-specific-user";
        };

        aerc.enable = true;
      };
    };
  };
}
