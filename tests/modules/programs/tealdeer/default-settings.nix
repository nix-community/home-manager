{
  config,
  ...
}:
{
  config = {
    programs.tealdeer = {
      package = config.lib.test.mkStubPackage {
        name = "tldr";
        version = "1.9.0";
      };
      enable = true;
    };

    nmt.script = ''
      assertPathNotExists "home-files/.config/tealdeer/config.toml"
    '';
  };
}
