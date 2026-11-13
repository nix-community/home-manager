{ config, ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    package = config.lib.test.mkStubPackage {
      name = "fzf";
      version = "0.73.0";
      buildScript = ''
        mkdir -p $out/bin $out/share/fzf
        cat > $out/bin/fzf << 'EOF'
        #!/bin/sh
        echo "Unexpected fzf execution" >&2
        exit 97
        EOF
      '';
    };
  };

  programs.zsh.enable = true;

  nmt.script = ''
    assertFileRegex home-files/.zshrc 'source.*fzf/share/fzf/completion.zsh'
    assertFileRegex home-files/.zshrc \
      'source.*fzf/share/fzf/key-bindings.zsh'
  '';
}
