{ config, ... }:

{
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;

    package = config.lib.test.mkStubPackage {
      name = "fzf";
      version = "0.73.0";
      buildScript = ''
        mkdir -p $out/bin
        cat > $out/bin/fzf << 'EOF'
        #!/bin/sh
        echo "Stub fzf"
        EOF
        chmod +x $out/bin/fzf
      '';
    };
  };

  programs.fish.enable = true;

  nmt.script = ''
    assertFileRegex home-files/.config/fish/config.fish \
      'fzf.*--fish.*source'
  '';
}
