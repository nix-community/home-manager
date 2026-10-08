{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      aliases = [ "webmaster@example.com" ];
      signature = {
        showSignature = "append";
        text = "Sent with home-manager";
      };
      mblaze.enable = true;
    };

    hm-account = {
      mblaze = {
        enable = true;
        sendMailCommand = "/bin/mysendmail --read-recipients";
        settings.Scan-Format = "%c%u%r %-3n %10d %17f %t %2i%s";
      };
    };
  };

  programs.mblaze = {
    enable = true;
    editor = "nvim";
  };

  nmt.script = ''
    primary=home-files/.mblaze/profile

    # the primary account is also written where mblaze looks when
    # MBLAZE is unset
    assertFileExists $primary
    assertFileContains $primary 'Local-Mailbox: H. M. Test <hm@example.com>'
    assertFileContains $primary 'Reply-From: H. M. Test <hm@example.com>'
    assertFileContains $primary 'Alternate-Mailboxes: webmaster@example.com'
    assertFileContains $primary 'FQDN: example.com'
    assertFileContains $primary 'Editor: nvim'

    # no synchroniser fills the account maildir, so drafts go to state
    assertFileContains $primary 'Drafts: /home/hm-user/.local/share/mblaze/hm@example.com/drafts'
    assertFileNotRegex $primary '^Outbox:'
    assertFileNotRegex $primary '^Maildir:'

    # no send command and no msmtp: mblaze falls back to sendmail
    assertFileNotRegex $primary '^Sendmail'

    # parsing of a profile halts on the first empty line
    assertFileNotRegex $primary '^$'

    assertFileContent home-files/.mblaze/signature \
      ${builtins.toFile "signature" "Sent with home-manager"}

    # the same account is reachable through MBLAZE as well
    assertFileContains home-files/.config/mblaze/hm@example.com/profile \
      'Local-Mailbox: H. M. Test <hm@example.com>'

    secondary=home-files/.config/mblaze/hm-account/profile

    assertFileExists $secondary
    assertFileContains $secondary 'Local-Mailbox: H. M. Test Jr. <hm@example.org>'
    assertFileContains $secondary 'Sendmail: /bin/mysendmail --read-recipients'
    assertFileContains $secondary 'Scan-Format: %c%u%r %-3n %10d %17f %t %2i%s'

    # a non-primary account is reachable through MBLAZE only
    assertPathNotExists home-files/.mblaze/hm-account
  '';
}
