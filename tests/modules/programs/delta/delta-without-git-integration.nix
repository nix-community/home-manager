{ config, ... }:
{
  programs.delta = {
    enable = true;
    enableGitIntegration = false;
    package = config.lib.test.mkStubPackage {
      name = "delta";
      buildScript = /* sh */ ''
        mkdir -p $out/bin
        echo "#!/bin/sh" > $out/bin/delta
        chmod +x $out/bin/delta
      '';
    };
    options.features = "line-numbers decorations";
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/git/config
    # the wrapper should be created only if git integration is disabled
    assertFileExists home-path/bin/.delta-wrapped
  '';
}
