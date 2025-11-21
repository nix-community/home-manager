{ config, ... }:

{
  programs.broot = {
    enable = true;
    package = (
      config.lib.test.mkStubPackage {
        name = "broot";
        extraAttrs = {
          src = config.lib.test.mkStubPackage {
            name = "broot-src";
            buildScript = ''
              mkdir -p $out/resources/default-conf/
              echo test > $out/resources/default-conf/conf.hjson
            '';
          };
        };
      }
    );

    settings.modal = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/broot/conf.hjson
    assertFileContains home-files/.config/broot/conf.hjson '"modal": true'
  '';
}
