{ config, ... }:

{
  programs = {
    fzf = {
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
          echo "Unexpected fzf execution" >&2
          exit 97
          EOF
          chmod +x $out/bin/fzf
        '';
      };
    };

    fish.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileNotRegex home-files/.config/fish/config.fish '^[[:space:]]*fzf_key_bindings[[:space:]]*$'

    assertFileRegex home-files/.config/fish/config.fish \
      'set -gx FZF_CTRL_R_COMMAND'

    overrideLine=$(grep -n 'set -gx FZF_CTRL_R_COMMAND' "$TESTED/home-files/.config/fish/config.fish" | head -n1 | cut -d: -f1)
    sourceLine=$(grep -n 'source.*fzf/share/fzf/key-bindings.fish' "$TESTED/home-files/.config/fish/config.fish" | head -n1 | cut -d: -f1)

    if [[ -z "$overrideLine" || -z "$sourceLine" || "$overrideLine" -ge "$sourceLine" ]]; then
      fail "fish fzf widget override must appear before fzf initialization"
    fi
  '';
}
