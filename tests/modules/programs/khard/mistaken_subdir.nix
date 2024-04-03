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

  programs.khard = {
    enable = true;
    settings = {
      general = {
        default_action = "list";
        editor = ["vim" "-i" "NONE"];
      };

      "contact table" = {
        group_by_address_book = true;
        reverse = false;
        preferred_phone_number_type = ["pref" "cell" "home"];
        preferred_email_address_type = ["pref" "work" "home"];
      };
    };
  };

  test.stubs.khard = {};

  nmt.script = ''
    assertFileContent \
      home-files/.config/khard/khard.conf \
      ${./mistaken_subdir_expected}
  '';
}
