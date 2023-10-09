{
  accounts.contact = {
    basePath = ".contacts";
    accounts.test1 = {
      local.type = "filesystem";
      khard.enable = true;
    };
    accounts.test2 = {
      local.type = "filesystem";
      khard.enable = true;
    };
  };

  programs.khard.enable = true;

  test.stubs.khard = { };

  nmt.script = ''
    assertFileContent \
      home-files/.config/khard/khard.conf \
      ${./multiple_accounts_expected}
  '';
}
