{ ... }:

{
  programs.tirith = {
    enable = true;
    allowlist = [
      "localhost"
      "example.com"
    ];
    policy = {
      version = 1;
      fail_mode = "open";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/tirith/allowlist
    assertFileContent \
      home-files/.config/tirith/allowlist \
      ${builtins.toFile "expected" ''
        localhost
        example.com
      ''}

    assertFileExists home-files/.config/tirith/policy.yaml
  '';
}
