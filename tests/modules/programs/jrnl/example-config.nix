{ config, ... }:

{
  programs.jrnl = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    settings = {
      colors = {
        body = "none";
        date = "black";
        tags = "yellow";
        title = "cyan";
      };
      default_hour = 23;
      default_minute = 59;
      editor = "nvim";
      encrypt = false;
      highlight = true;
      indent_character = "|";
      journals.default.journal = "/home/hm-user/jrnl/journal.txt";
      linewrap = 79;
      tagsymbols = "#@";
      template = false;
      timeformat = "%d. %h %Y %H:%M";
    };
  };

  test.stubs.jrnl = { };

  nmt.script = ''
    assertFileContent \
      home-files/.config/jrnl/jrnl.yaml \
      ${./example-config.yaml}
  '';
}
