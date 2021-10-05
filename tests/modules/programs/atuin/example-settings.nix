{ ... }:

{
  programs.atuin = {
    enable = true;

    settings = {
      db_path = "~/.atuin-history.db";
      dialect = "us";
      auto_sync = true;
      search-mode = "fulltext";
    };
  };

  test.stubs = {
    atuin = { };
    bash-preexec = { };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/atuin/config.toml \
      ${
        builtins.toFile "example-settings-expected.toml" ''
          auto_sync = true
          db_path = "~/.atuin-history.db"
          dialect = "us"
          search-mode = "fulltext"
        ''
      }
  '';
}
