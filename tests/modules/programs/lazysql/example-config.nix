{
  programs.lazysql = {
    enable = true;
    settings = {
      database = [
        {
          Name = "Production database";
          Provider = "postgres";
          DBName = "foo";
          URL = "postgres://postgres:urlencodedpassword@localhost:$${port}/foo";
          Commands = [
            {
              Command = "ssh -tt remote-bastion -L $${port}:localhost:5432";
              WaitForPort = "$${port}";
            }
          ];
        }
        {
          Name = "Development database";
          Provider = "postgres";
          DBName = "foo";
          URL = "postgres://postgres:urlencodedpassword@localhost:5432/foo";
        }
      ];
      application = {
        DefaultPageSize = 300;
        DisableSidebar = false;
        SidebarOverlay = false;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/lazysql/config.toml
    assertFileContent home-files/.config/lazysql/config.toml \
    ${./example-config.toml}
  '';
}
