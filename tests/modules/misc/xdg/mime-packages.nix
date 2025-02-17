{ config, ... }:
let inherit (config.lib.test) mkStubPackage;
in {
  config = {
    xdg.mime.enable = true;
    xdg.mime.sharedMimeInfoPackage = mkStubPackage {
      name = "update-mime-database";
      buildScript = ''
        mkdir -p $out/bin
        echo '#!/bin/sh' > $out/bin/update-mime-database
        echo 'mkdir -p $out/share/mime && touch $out/share/mime/mime.cache' >> $out/bin/update-mime-database
        chmod +x $out/bin/update-mime-database
      '';
    };
    xdg.mime.desktopFileUtilsPackage = mkStubPackage {
      name = "desktop-file-utils";
      buildScript = ''
        mkdir -p $out/bin
        echo '#!/bin/sh' > $out/bin/update-desktop-database
        echo 'mkdir -p $out/share/applications/ && ln -s ${
          ./mime-expected.cache
        } $out/share/applications/mimeinfo.cache' >> $out/bin/update-desktop-database
        chmod +x $out/bin/update-desktop-database
      '';
    };
    nmt.script = ''
      assertFileExists home-path/share/applications/mimeinfo.cache # Check that update-desktop-database created file
      # Check that update-desktop-database file matches expected
      assertFileContent \
      home-path/share/applications/mimeinfo.cache \
        ${./mime-expected.cache}

      assertDirectoryExists home-path/share/mime # Check that update-mime-database created directory
      assertFileExists home-path/share/mime/mime.cache # Check that update-mime-database created file

    '';
  };
}
