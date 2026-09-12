{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts."hm@example.com" = {
    imap.authentication = "login";
    smtp.authentication = "login";
    himalaya.enable = true;
    mblaze.enable = true;
  };

  # enabling both halves is all it takes
  programs = {
    himalaya.enable = true;
    mblaze.enable = true;
  };

  nmt.script = ''
    profile=home-files/.mblaze/profile

    # himalaya is the transport of the composer it is paired with, over
    # the msmtp fallback the mblaze module would otherwise apply
    assertFileRegex $profile '^Sendmail: /nix/store/.*mblaze-send-hm-example.com$'

    assertFileExists home-path/bin/himalaya-mcom
    assertFileExists home-path/bin/himalaya-mrep
    assertFileExists home-path/bin/himalaya-mfwd
    assertFileExists home-path/bin/himalaya-mshow

    # the profile is the mblaze module's business, not himalaya's
    assertPathNotExists home-files/.config/himalaya/composer
  '';
}
