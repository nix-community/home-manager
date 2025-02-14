{
  accounts.contact = {
    basePath = "/home/user/who/likes///";
    accounts.forward = {
      local.type = "filesystem";
      khard = {
        enable = true;
        defaultCollection = "////slashes//a/lot";
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
