{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      mbsync.enable = true;
      msmtp.enable = true;
      mblaze.enable = true;
    };

    hm-account = {
      mujmap.enable = true;
      folders.drafts = null;
      mblaze.enable = true;
    };
  };

  programs = {
    mblaze.enable = true;
    msmtp.enable = true;
  };

  nmt.script = ''
    profile=home-files/.mblaze/profile

    # a synchronised maildir is where drafts and sent copies belong
    assertFileContains $profile 'Maildir: /home/hm-user/Mail/hm@example.com'
    assertFileContains $profile 'Drafts: /home/hm-user/Mail/hm@example.com/Drafts'
    assertFileContains $profile 'Outbox: /home/hm-user/Mail/hm@example.com/Sent'

    # an msmtp account needs no explicit send command
    assertFileContains $profile 'Sendmail: msmtpq --read-envelope-from --read-recipients'

    mujmap=home-files/.config/mblaze/hm-account/profile

    # mujmap fills the account maildir as well
    assertFileContains $mujmap 'Maildir: /home/hm-user/Mail/hm-account'
    assertFileContains $mujmap 'Outbox: /home/hm-user/Mail/hm-account/Sent'

    # an account with no drafts folder keeps its drafts out of the maildir
    assertFileContains $mujmap 'Drafts: /home/hm-user/.local/share/mblaze/hm-account/drafts'
  '';
}
