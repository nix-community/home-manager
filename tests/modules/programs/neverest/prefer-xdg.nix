_: {
  home.enableNixpkgsReleaseCheck = false;
  home.preferXdgDirectories = true;

  test.stubs.neverest = { };

  programs.neverest.enable = true;

  accounts.email = {
    maildirBasePath = "mail";
    accounts."example" = {
      primary = true;
      address = "user@example.com";
      userName = "user@example.com";
      passwordCommand = "pass example";
      maildir.path = "example";
      imap = {
        host = "imap.example.com";
        tls.enable = true;
      };
      neverest.enable = true;
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/neverest/config.toml"
    assertPathNotExists "home-files/Library/Application Support/neverest/config.toml"
  '';
}
