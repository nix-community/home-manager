{ config, ... }:

{
  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;

      historyWidget = {
        command = "global-history";
        zsh.command = "";
      };

      fileWidget.zsh.command = "$HOME/bin/files";

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

    zsh.enable = true;
  };

  nmt.script = ''
    assertFileRegex home-files/.zshrc \
      'export FZF_CTRL_R_COMMAND='

    assertFileContains home-files/.zshrc \
      'export FZF_CTRL_T_COMMAND="$HOME/bin/files"'

    overrideLine=$(grep -n 'export FZF_CTRL_R_COMMAND=' "$TESTED/home-files/.zshrc" | head -n1 | cut -d: -f1)
    sourceLine=$(grep -n 'fzf.*--zsh' "$TESTED/home-files/.zshrc" | head -n1 | cut -d: -f1)

    if [[ -z "$overrideLine" || -z "$sourceLine" || "$overrideLine" -ge "$sourceLine" ]]; then
      fail "zsh fzf widget override must appear before fzf initialization"
    fi
  '';
}
