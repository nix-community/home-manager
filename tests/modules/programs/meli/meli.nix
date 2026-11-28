{
  imports = [ ../../accounts/email-test-accounts.nix ];
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
      meli = {
        enable = true;
        settings = {
          listing.index_style = "compact";
        };
      };
      smtp.port = 1848;
    };
    jmap-account = {
      address = "hm@jmap.invalid";
      userName = "home.manager.jr";
      realName = "H. M. Test Jr.";
      passwordCommand = "password-command 2";
      jmap.host = "jmap.invalid";
      meli = {
        enable = true;
      };
    };
  };

  nmt.script = ''
        assertFileExists home-files/.config/meli/config.toml
    		assertFileContent home-files/.config/meli/config.toml ${./expected.toml}
    	'';
}
