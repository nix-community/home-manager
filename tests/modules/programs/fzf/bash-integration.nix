{ config, ... }:

{
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;

    package = config.lib.test.mkStubPackage {
      name = "fzf";
      version = "0.73.0";
      buildScript = ''
        mkdir -p $out/bin $out/share/fzf
        cat > $out/bin/fzf << 'EOF'
        #!/bin/sh
        echo "Stub fzf"
        EOF
      '';
    };
  };

  programs.bash.enable = true;

  nmt.script = ''
    assertFileRegex home-files/.bashrc \
      'eval.*fzf.*bash'
  '';
}
