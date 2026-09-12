{ pkgs, ... }:
{
  home.enableNixpkgsReleaseCheck = false;

  test.stubs.neverest = { };

  programs.neverest.enable = true;

  accounts.email = {
    maildirBasePath = "mail";
    accounts = {
      "filtered" = {
        primary = true;
        address = "filtered@example.com";
        userName = "filtered@example.com";
        passwordCommand = "pass filtered";
        maildir.path = "filtered";
        imap = {
          host = "imap.example.com";
          tls.enable = true;
        };
        neverest = {
          enable = true;
          mailboxFilters.include = [
            "INBOX"
            "Sent"
          ];
        };
      };

      "protected" = {
        address = "protected@example.com";
        userName = "protected@example.com";
        passwordCommand = "pass protected";
        maildir.path = "protected";
        imap = {
          host = "imap.example.com";
          tls.enable = true;
        };
        neverest = {
          enable = true;
          protectServer = true;
        };
      };

      # No TLS and no explicit port: exercises the "none" encryption + 143
      # default port, plus the exclude branch of mailboxFilters.
      "plaintext" = {
        address = "plaintext@example.com";
        userName = "plaintext@example.com";
        passwordCommand = "pass plaintext";
        maildir.path = "plaintext";
        imap = {
          host = "imap.example.com";
          tls.enable = false;
        };
        neverest = {
          enable = true;
          mailboxFilters.exclude = [ "Spam" ];
        };
      };
    };
  };

  nmt.script =
    let
      configFile =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/neverest/config.toml"
        else
          "home-files/.config/neverest/config.toml";
    in
    ''
      assertFileExists "${configFile}"

      # mailboxFilters.include produces accounts.<name>.folder.filters.include
      # (the account-level FolderConfig, not a per-backend key).
      assertFileRegex "${configFile}" '\[accounts\.filtered\.folder\.filters\]'
      assertFileRegex "${configFile}" 'include = \["INBOX", "Sent"\]'

      # mailboxFilters.exclude produces the complementary filters section.
      assertFileRegex "${configFile}" '\[accounts\.plaintext\.folder\.filters\]'
      assertFileRegex "${configFile}" 'exclude = \["Spam"\]'

      # protectServer = true sets create/delete to false, but only on the
      # right (IMAP) side's folder and message permissions -- these live
      # under [accounts.<name>.right.folder.permissions] /
      # [accounts.<name>.right.message.permissions] per the real
      # BackendGlobalConfig schema, not a top-level "mailbox"/"imap" key.
      assertFileRegex "${configFile}" '\[accounts\.protected\.right\.folder\.permissions\]'
      assertFileRegex "${configFile}" '\[accounts\.protected\.right\.message\.permissions\]'
      assertFileRegex "${configFile}" 'create = false'
      assertFileRegex "${configFile}" 'delete = false'

      # Real ImapConfig auth is a flattened "passwd" field (Secret enum),
      # not "sasl.plain.username/password".
      assertFileRegex "${configFile}" 'login = '
      assertFileRegex "${configFile}" '\[accounts\.filtered\.right\.backend\.passwd\]'
      assertFileRegex "${configFile}" 'command = '

      # host/port/encryption are separate fields, not a "server" URL string.
      # TLS defaults to "tls" + 993, plaintext to "none" + 143.
      assertFileRegex "${configFile}" 'encryption = "tls"'
      assertFileRegex "${configFile}" 'port = 993'
      assertFileRegex "${configFile}" 'encryption = "none"'
      assertFileRegex "${configFile}" 'port = 143'
    '';
}
