{ lib, pkgs, ... }:

{
  programs.khard = {
    enable = true;
    defaultAction = "list";
    settings = {
      general = {
        debug = false;
        editor = [ "vim" "-i" "NONE" ];
        merge_editor = "vimdiff";
      };
      "contact table" = {
        display = "first_name";
        group_by_addressbook = false;
        reverse = false;
        show_nicknames = false;
        show_uids = true;
        show_kinds = false;
        sort = "last_name";
        localize_dates = true;
        preferred_phone_number_type = [ "pref" "cell" "home" ];
        preferred_email_address_type = [ "pref" "work" "home" ];
      };
      vcard = {
        private_objects = [ "Jabber" "Skype" "Twitter" ];
        preferred_version = "3.0";
        search_in_source_files = false;
        skip_unparsable = false;
      };
    };
  };
  accounts.contact.accounts = {
    family = {
      khard.enable = true;
      local.path = "~/.contacts/family/";
    };
    friends = {
      khard.enable = true;
      local.path = "~/.contacts/friends/";
    };
  };

  test.stubs = { khard = { }; };

  nmt.script = ''
    assertFileExists home-files/.config/khard/khard.conf
    assertFileContent home-files/.config/khard/khard.conf ${
      ./example-config.expected
    }
  '';
}
