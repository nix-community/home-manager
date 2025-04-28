{
  programs.gh = {
    enable = true;
    hosts."github.com" = {
      git_protocol = "ssh";
      user = "my_username";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/gh/hosts.yml
    assertFileContent home-files/.config/gh/hosts.yml ${builtins.toFile "hosts.yml" ''
      github.com:
        git_protocol: ssh
        user: my_username
    ''}
  '';
}
