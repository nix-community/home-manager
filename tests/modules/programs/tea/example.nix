{
  programs.tea = {
    enable = true;

    logins = [
      {
        default = true;
        name = "code.oliverdavies.uk";
        token = "abc123";
        url = "https://code.oliverdavies.uk";
        user = "opdavies";
        versionCheck = true;
      }
      {
        insecure = true;
        name = "example.com";
        ssh = {
          host = "git.example.com";
          key = "/home/opdavies/.ssh/id_rsa";
        };
        tokenFile = "/home/opdavies/.tea-token";
        url = "https://example.com";
      }
    ];

    preferences = {
      editor = false;

      flag_defaults = {
        remote = "";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/tea/config.yml

    assertFileContent home-files/.config/tea/config.yml \
      ${./example.yml}
  '';
}
