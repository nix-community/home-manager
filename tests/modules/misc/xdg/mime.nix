{ ... }: {
  config = {
    xdg.mime.enable = true;
    xdg.desktopEntries = {
      mime-test = { # mime info test
        name = "mime-test";
        mimeType = [ "text/html" "text/xml" ];
      };

    };

    nmt.script = ''
      assertFileExists home-path/share/applications/mimeinfo.cache # Check that update-desktop-database created file
      # Check that update-desktop-database file matches expected
      assertFileContent \
        home-path/share/applications/mimeinfo.cache \
        ${./mime-expected.cache}

      assertDirectoryExists home-path/share/mime # Check that update-mime-database created directory
      assertDirectoryNotEmpty home-path/share/mime # Check that update-mime-database created files

    '';
  };
}
