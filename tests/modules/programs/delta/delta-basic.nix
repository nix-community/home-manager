{ config, ... }:

{
  programs.delta = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "delta";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/delta
        chmod 755 $out/bin/delta
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
    # Git config should NOT contain delta configuration since enableGitIntegration is false by default
    assertFileNotRegex home-files/.config/git/config 'pager = .*/bin/delta'
    assertFileNotRegex home-files/.config/git/config 'diffFilter = .*/bin/delta'

    # Verify the wrapper passes the config flag
    # The wrapper script should contain --config flag
    assertFileRegex home-path/bin/delta '\-\-config'
  '';
}
