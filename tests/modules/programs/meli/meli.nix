{

  imports = [
    ../../accounts/email-test-accounts.nix
  ];
  programs.meli = {
    enable = true;
    settings = {
      shortcuts = {
        general = {
          scroll_up = "k";
          scroll_down = "j";
        };
      };
    };
  };
  accounts.email.accounts = {
    "hm@example.com" = {
      meli.enable = true;
      smtp.port = 1848;
    };
  };

  nmt.script = ''
        assertFileExists home-files/.config/meli/config.toml
    		assertFileContent home-files/.config/meli/config.toml ${./expected.toml}
    	'';
}
