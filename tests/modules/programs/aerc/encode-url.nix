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
        assertFileContent ${dir}/accounts.conf ${./encode-url.expected}
      '';
    programs.aerc = {
      enable = true;
      extraConfig.general.unsafe-accounts-conf = true;
    };

    accounts.email.accounts = {
      basic = {
        realName = "Foo Bar";
        userName = "user@example.com";
        address = "user@example.com";
        primary = true;
        aerc.enable = true;
        imap.host = "imap.example.com";
        smtp.host = "smtp.example.com";
      };
    };
  };
}
