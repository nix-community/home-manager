{ config, ... }:

{
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = false;

    package = config.lib.test.mkStubPackage {
      name = "fzf";
      version = "0.48.0";
      buildScript = ''
        mkdir -p $out/bin
        cat > $out/bin/fzf << 'EOF'
        #!/bin/sh
        echo "Unexpected fzf execution" >&2
        exit 97
        EOF
        chmod +x $out/bin/fzf
      '';
    };
  };

  programs.fish.enable = true;

  nmt.script = ''
    assertFileContains home-files/.config/fish/config.fish 'fzf_key_bindings'
    assertFileRegex home-files/.config/fish/config.fish 'if test -f .*fzf/share/fzf/completion.fish'
    assertFileRegex home-files/.config/fish/config.fish \
      'source.*fzf/share/fzf/key-bindings.fish'
  '';
}
