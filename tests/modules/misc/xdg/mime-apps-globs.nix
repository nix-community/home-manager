_:

{
  xdg.mimeApps = {
    enable = true;

    associations = {
      added."image/*" = "added.desktop";
      removed."video/*" = "removed.desktop";
    };

    defaultApplications = {
      "text/*" = [
        "editor.desktop"
        "secondEditor.desktop"
      ];
      "text/html" = "browser.desktop";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/mimeapps.list
    assertFileRegex home-files/.config/mimeapps.list '^image/png=added\.desktop$'
    assertFileRegex home-files/.config/mimeapps.list '^video/mp4=removed\.desktop$'
    assertFileRegex home-files/.config/mimeapps.list '^text/plain=editor\.desktop;secondEditor\.desktop$'
    assertFileRegex home-files/.config/mimeapps.list '^text/html=browser\.desktop$'
    assertFileNotRegex home-files/.config/mimeapps.list '^text/html=editor\.desktop;secondEditor\.desktop$'
    assertFileNotRegex home-files/.config/mimeapps.list '^.*\*='
  '';
}
