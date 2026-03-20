{
  accounts.contact = {
    basePath = "/home/user/who/likes///";
    accounts.kebap-case = {
      local.type = "filesystem";
      khard = {
        enable = true;
        addressbooks = [ "named-abook" ];
      };
    };
  };

  programs.khard.enable = true;

  nmt.script = ''
    assertFileContent \
      home-files/.config/khard/khard.conf \
      ${./dirty_path_expected}
  '';
}
