{ config, pkgs, ... }:
{
  programs.aerc = {
    enable = true;
    package = null;
    extraConfig.general.unsafe-accounts-conf = true;
  };

  accounts.email.accounts.example = {
    address = "example@mail.invalid";
    realName = "Example";
    primary = true;
    aerc.enable = true;
    notmuch.enable = true;
    maildir.path = "custom-notmuch";
  };

  nmt.script =
    let
      dir =
        if (pkgs.stdenv.hostPlatform.isDarwin && !config.xdg.enable) then
          "home-files/Library/Preferences/aerc"
        else
          "home-files/.config/aerc";
    in
    ''
      assertFileContent ${dir}/accounts.conf ${./notmuch-null-package.expected}
    '';
}
