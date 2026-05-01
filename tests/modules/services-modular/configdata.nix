{ pkgs, ... }:
{
  home.services.demo = {
    process.argv = [ "${pkgs.coreutils}/bin/true" ];
    configData."config.toml".text = ''
      [server]
      port = 1234
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/system-services/demo/config.toml
    assertFileContains home-files/.config/system-services/demo/config.toml 'port = 1234'
  '';
}
