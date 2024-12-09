{ ... }:

{
  programs.zk = {
    enable = true;
    settings = {
      extra = { author = "Mickaël"; };

      note = {
        default-title = "Untitled";
        extension = "md";
        filename = "{{id}}-{{slug title}}";
        id-case = "lower";
        id-charset = "alphanum";
        id-length = 4;
        template = "default.md";
        language = "en";
      };

      notebook = { dir = "~/notebook"; };
    };
  };

  test.stubs.zk = { };

  nmt.script = ''
    assertFileExists home-files/.config/zk/config.toml
    assertFileContent home-files/.config/zk/config.toml ${./expected.toml}
  '';
}
