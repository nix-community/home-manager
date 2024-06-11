{ config, pkgs, ... }:

{
  config = {
    services.radicle = { enable = true; };

    nmt.script = ''
      assertFileContent \
        home-files/.radicle/config.json \
        ${./basic-configuration.json}
    '';
  };
}
