_:

{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/*" = "editor.desktop";
      "text/html" = "browser.desktop";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/mimeapps.list
    assertFileRegex home-files/.config/mimeapps.list '^text/plain=editor\.desktop$'
    assertFileRegex home-files/.config/mimeapps.list '^text/html=browser\.desktop$'
  '';
}
