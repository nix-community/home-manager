{ config, ... }:

{
  programs.bash.enable = true;

  programs.tere = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "tere";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/tere
        chmod +x $out/bin/tere
      '';
    };
    enableBashIntegration = true;
  };

  nmt.script = ''
    assertFileExists home-path/bin/tere

    assertFileExists home-files/.bashrc
    assertFileContains home-files/.bashrc 'tere() {'
    assertFileContains home-files/.bashrc 'local result=$(command tere "$@")'
    assertFileContains home-files/.bashrc '[ -n "$result" ] && cd -- "$result"'
  '';
}
