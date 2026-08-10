{
  time = "2026-08-10T12:20:20+00:00";
  condition = true;
  message = ''
    A new module is available: 'programs.mblaze'.

    mblaze is a suite of Unix utilities to deal with Maildir. Among
    them is a composer that opens a draft in your editor, quotes the
    message you are replying to and assembles MIME, which pairs it
    with a mail program that does none of those.

    mblaze itself reads a single profile, so every account enabled
    through 'accounts.email.accounts.<name>.mblaze.enable' is given
    one of its own, picked by pointing the MBLAZE environment
    variable at it. The primary account is written to ~/.mblaze as
    well, so that a bare 'mcom' works with no environment set up.

    Messages are handed to the command in
    'accounts.email.accounts.<name>.mblaze.sendMailCommand', which
    defaults to msmtp when msmtp is enabled for that account.
  '';
}
