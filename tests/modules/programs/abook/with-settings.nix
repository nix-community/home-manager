{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.abook = {
      enable = true;

      extraConfig = ''
        #  Defining a new custom field
        # -----------------------------

        field pager = Pager
        field address_lines = Address, list
        field birthday = Birthday, date

        #  Defining a view/tab
        # ---------------------

        view CONTACT = name, email
        view ADDRESS = address_lines, city, state, zip, country
        view PHONE = phone, workphone, pager, mobile, fax
        view OTHER = url, birthday

        # Automatically save database on exit
        set autosave=true
      '';
    };

    test.stubs.abook = { };

    nmt.script = ''
      assertFileExists home-files/.config/abook/abookrc
      assertFileContent home-files/.config/abook/abookrc ${./with-settings.cfg}
    '';
  };
}
