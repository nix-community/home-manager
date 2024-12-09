{ config, pkgs, ... }:

{
  services.mopidy = {
    enable = true;
    extensionPackages = [ pkgs.mopidy-local ];
  };

  test.stubs = {
    mopidy = {
      version = "0";
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/mopidy
        chmod +x $out/bin/mopidy
      '';
    };

    mopidy-local = { };
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/mopidy.service
    assertFileExists home-files/.config/systemd/user/mopidy-scan.service
  '';
}
