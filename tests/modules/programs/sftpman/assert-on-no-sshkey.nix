{
  config = {
    programs.sftpman = {
      enable = true;

      mounts = {
        mount1 = {
          host = "host1.example.com";
          mountPoint = "/path/to/somewhere";
          user = "root";
        };
      };
    };

    test.stubs.sftpman = { };

    test.asserts.assertions.expected = [''
      sftpman mounts using authentication type "publickey" but missing 'sshKey': mount1
    ''];
  };
}
