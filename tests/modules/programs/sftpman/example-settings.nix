{
  config = {
    programs.sftpman = {
      enable = true;
      defaultSshKey = "/home/user/.ssh/id_ed25519";

      mounts = {
        mount1 = {
          host = "host1.example.com";
          mountPoint = "/path/to/somewhere";
          user = "root";
          mountOptions = [ "idmap=user" ];
        };
        mount2 = {
          host = "host2.example.com";
          mountPoint = "/another/path";
          user = "someuser";
          authType = "password";
          sshKey = null;
        };
        mount3 = {
          host = "host3.example.com";
          mountPoint = "/yet/another/path";
          user = "user";
          sshKey = "/home/user/.ssh/id_rsa";
        };
      };
    };

    test.stubs.sftpman = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/sftpman/mounts/mount1.json \
        ${./expected-mount1.json}
      assertFileContent \
        home-files/.config/sftpman/mounts/mount2.json \
        ${./expected-mount2.json}
      assertFileContent \
        home-files/.config/sftpman/mounts/mount3.json \
        ${./expected-mount3.json}
    '';
  };
}
