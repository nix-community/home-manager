{
  programs.formiko = {
    enable = true;
    settings = {
      main = {
        preview = 0;
        parser = "json";
        auto_scroll = true;
        writer = "tiny";
      };

      editor = {
        period_save = true;
        check_spelling = false;
        auto_indent = false;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/formiko.ini
    assertFileContent home-files/.config/formiko.ini \
      ${./formiko.ini}
  '';
}
