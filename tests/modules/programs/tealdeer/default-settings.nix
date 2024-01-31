{ config, ... }: {
  config = {
    programs.tealdeer = {
      package = config.lib.test.mkStubPackage { name = "tldr"; };
      enable = true;
    };

    nmt.script = ''
      assertFileRegex activate '/nix/store/.*tealdeer.*/bin/tldr --update'
    '';
  };
}
