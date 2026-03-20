{
  programs.pubs = {
    enable = true;

    extraConfig = ''
      [main]
      pubsdir = ~/.pubs
      docsdir = ~/.pubs/doc
      doc_add = link
      open_cmd = xdg-open

      [plugins]
      active = git,alias

      [[alias]]

      [[[la]]]
      command = list -a
      description = lists papers in lexicographic order

      [[git]]
      quiet = True
      manual = False
      force_color = False
    '';
  };

  nmt.script = ''
    assertFileContent \
      home-files/.pubsrc ${./pubs-example-settings-expected-pubsrc}
  '';
}
