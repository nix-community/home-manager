{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    accounts.email.accounts."hm@example.com".msmtp.enable = true;
    programs.git = {
      enable = true;
      package = pkgs.gitMinimal;
      userEmail = "hm@example.com";
      userName = "H. M. Test";
    };

    home.stateVersion = "20.09";

    test.stubs.msmtp = { };

    nmt.script = ''
      function assertGitConfig() {
        local value
        value=$(${pkgs.gitMinimal}/bin/git config \
          --file $TESTED/home-files/.config/git/config \
          --get $1)
        if [[ $value != $2 ]]; then
          fail "Expected option '$1' to have value '$2' but it was '$value'"
        fi
      }

      assertFileExists home-files/.config/git/config
      assertFileContent home-files/.config/git/config \
        ${./git-with-msmtp-expected.conf}

      assertGitConfig "sendemail.hm@example.com.from" "hm@example.com"
      assertGitConfig "sendemail.hm-account.from" "hm@example.org"
      assertGitConfig "sendemail.hm@example.com.smtpServer" "${pkgs.msmtp}/bin/msmtp"
      assertGitConfig "sendemail.hm@example.com.envelopeSender" "auto"
    '';
  };
}
