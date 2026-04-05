{
  config = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        foobar = {
          extraOptions = {
            Foo = "foo";
            Bar = false;
          };
        };
      };
    };

    test.asserts.assertions.expected = [
      ''
        `programs.ssh.matchBlocks.foobar` sets `extraOptions`, which has
        been removed.
      ''
    ];
  };
}
