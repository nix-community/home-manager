{
  accounts.contact = {
    basePath = ".contacts";
    accounts.test1 = {
      local.type = "filesystem";
      khard = {
        enable = true;
        addressbooks = [
          "home"
          "work"
          "family"
        ];
      };
    };
    accounts.test2 = {
      local.type = "filesystem";
      khard.enable = true;
    };
  };

  programs.khard.enable = true;

  nmt.script = ''
    assertFileContent \
      home-files/.config/khard/khard.conf \
      ${./multiple_with_abooks_expected}
  '';
}
