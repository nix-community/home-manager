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
    options = {
      features = "line-numbers decorations";
      syntax-theme = "Dracula";
      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
      };
    };
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileContent home-files/.config/git/config ${./delta-without-git-integration.gitconfig}
  '';
}
