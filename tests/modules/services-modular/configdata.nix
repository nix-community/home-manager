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
    assertFileContent home-files/.config/home-services/demo/config.toml ${./config.toml}
  '';
}
