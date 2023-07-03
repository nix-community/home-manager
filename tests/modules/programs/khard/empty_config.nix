{
  accounts.contact = {
    basePath = ".contacts";
    accounts.test = {
      local.type = "filesystem";
      khard.enable = true;
    };
  };

  programs.khard.enable = true;

  test.stubs.khard = { };

  nmt.script = ''
    assertFileContent \
      home-files/.config/khard/khard.conf \
      ${./empty_config_expected}
  '';
}
