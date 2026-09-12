{ config, ... }:
{
  time = "2026-08-10T09:00:00+00:00";
  condition = config.programs.himalaya.enable;
  message = ''
    The 'programs.himalaya' module now generates a Himalaya CLI v2
    configuration. The v2 schema shares almost nothing with v1, and since v2
    ignores unknown keys instead of rejecting them, a v1 configuration file
    silently yields accounts with no backend at all.

    The generated configuration changed as follows:

    - The IMAP, Maildir and SMTP backends moved from `backend` and
      `message.send.backend` to the top-level `imap`, `maildir` and `smtp`
      tables. Host, port and implicit TLS are folded into a single
      `imap.server` / `smtp.server` URL, and STARTTLS became a separate
      `imap.starttls` / `smtp.starttls` switch.
    - Credentials moved to `imap.sasl.plain` / `smtp.sasl.plain`, with
      'accounts.email.accounts.<name>.passwordCommand' now feeding
      `password.command`.
    - `folder.aliases` became `mailbox.alias`.
    - The Notmuch and Sendmail backends were removed upstream. An account
      relying on Notmuch now falls back to reading its Maildir, and an account
      without an 'accounts.email.accounts.<name>.smtp' configuration can
      no longer send messages.
    - The desktop entry is gone. It existed to register a `mailto:` handler,
      which v2 dropped along with URI handling, and what remained pointed a
      menu item at a bare `himalaya`, which runs the first-run account wizard.
    - An account that names no `authentication` mechanism now authenticates
      with SASL LOGIN rather than PLAIN, and a mechanism Himalaya cannot speak
      is an error instead of being silently downgraded to PLAIN.
    - `accounts.email.accounts.<name>.jmap` is now used when the account has no
      IMAP configuration, authenticating with HTTP Basic.

    Himalaya manages messages, it does not compose them: there is no editor
    loop, no quoting of the message being replied to and no MIME builder.
    mblaze has all three, so the two are now paired automatically. Turn on
    'programs.mblaze.enable' next to this module, and enable both halves on an
    account through 'accounts.email.accounts.<name>.himalaya.enable' and
    'accounts.email.accounts.<name>.mblaze.enable'. That installs the
    'himalaya-mcom', 'himalaya-mrep', 'himalaya-mfwd' and 'himalaya-mshow'
    wrappers, and points mblaze at Himalaya for sending.

    Anything set through 'programs.himalaya.settings' or
    'accounts.email.accounts.<name>.himalaya.settings' is passed through
    verbatim and has to be migrated by hand. See the upstream
    [migration guide](https://github.com/pimalaya/himalaya/blob/master/MIGRATION.md).

    To stay on Himalaya CLI v1, pin
    'programs.himalaya.package' to an older revision and write the
    configuration file yourself through 'xdg.configFile'.
  '';
}
