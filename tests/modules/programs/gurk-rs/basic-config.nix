{ pkgs, ... }:
{
  programs.gurk-rs = {
    enable = true;
    settings = {
      first_name_only = false;
      show_receipts = true;
      notifications = true;
      bell = true;
      colored_messages = false;
      default_keybindings = true;
      user = {
        name = "MYNAME";
        phone_number = "MYNUMBER";
      };
      keybindings = { };
    };
  };

  nmt.script =
    let
      configFile =
        if pkgs.stdenv.isDarwin then
          "home-files/Library/Application\\ Support/gurk/gurk.toml"
        else
          "home-files/.config/gurk/gurk.toml";
    in
    ''
      assertFileExists ${configFile}
      assertFileContent ${configFile} \
        ${pkgs.writeText "settings-expected" ''
          bell = true
          colored_messages = false
          default_keybindings = true
          first_name_only = false
          notifications = true
          show_receipts = true

          [keybindings]

          [user]
          name = "MYNAME"
          phone_number = "MYNUMBER"
        ''}
    '';
}
