{ config, ... }:

{
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;

    historyWidget = {
      command = "global-history";
      fish.command = "";
    };

    package = config.lib.test.mkStubPackage {
      name = "fzf";
      version = "0.73.0";
      buildScript = ''
        mkdir -p $out/bin
        cat > $out/bin/fzf <<'EOF'
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
      'set -gx FZF_CTRL_R_COMMAND'

    overrideLine=$(grep -n 'set -gx FZF_CTRL_R_COMMAND' "$TESTED/home-files/.config/fish/config.fish" | head -n1 | cut -d: -f1)
    sourceLine=$(grep -n 'fzf.*--fish.*source' "$TESTED/home-files/.config/fish/config.fish" | head -n1 | cut -d: -f1)

    if [[ -z "$overrideLine" || -z "$sourceLine" || "$overrideLine" -ge "$sourceLine" ]]; then
      fail "fish fzf widget override must appear before fzf initialization"
    fi
  '';
}
