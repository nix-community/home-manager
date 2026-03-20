{
  programs.jrnl = {
    enable = true;
    settings = {
      journals = {
        default = "~/journals/journal.txt";
        work = "~/journals/work.txt";
      };
      colors = {
        body = "none";
        date = "green";
        tags = "yellow";
        title = "cyan";
      };
      default_hour = 9;
      default_minute = 0;
      editor = "vim";
      encrypt = false;
      highlight = true;
      indent_character = "|";
      linewrap = 80;
      tagsymbols = "@";
      template = false;
      timeformat = "%Y-%m-%d %H:%M";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/jrnl/jrnl.yaml
    assertFileContent home-files/.config/jrnl/jrnl.yaml ${./jrnl-basic-settings-expected.yaml}
  '';
}
