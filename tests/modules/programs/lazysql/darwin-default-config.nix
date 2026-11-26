let
  example = import ./example-config.nix;
  configFile = "home-files/Library/Application Support/lazysql/config.toml";
in
{
  xdg.enable = false;
  programs.lazysql = example.programs.lazysql // {
    package = null;
  };

  nmt.script = ''
    assertFileContent "${configFile}" ${./example-config.toml}
    assertPathNotExists home-files/.config/lazysql/config.toml
  '';
}
