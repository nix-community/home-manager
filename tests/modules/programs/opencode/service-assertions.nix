{ config, ... }:

{
  programs.opencode = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "opencode";
      version = "1.18.31";
    };

    service = {
      enable = true;
      settings = {
        password = "secret";
        remote.route = "https://remote.example";
        remoteAccepted = true;
        port = 70000;
        hostname = 123;
        disabled = "yes";
        cors = "https://example.com";
        env = {
          FOO = 1;
          BAR = true;
        };
      };
    };
  };

  test.asserts.assertions.expected = [
    "`programs.opencode.service` requires OpenCode 2 or later"
    "`programs.opencode.service.settings.password` is not supported; use `programs.opencode.service.passwordFile` to keep the password out of the Nix store"
    "`programs.opencode.service.settings.remote` is managed by OpenCode; use `opencode service set remote`"
    "`programs.opencode.service.settings.remoteAccepted` is managed by OpenCode; use `opencode pair --remote`"
    "`programs.opencode.service.settings.port` must be an integer between 1 and 65535"
    "`programs.opencode.service.settings.hostname` must be a string"
    "`programs.opencode.service.settings.disabled` must be a boolean"
    "`programs.opencode.service.settings.cors` must be a list of strings"
    "`programs.opencode.service.settings.env` must be an attribute set of strings"
  ];
}
