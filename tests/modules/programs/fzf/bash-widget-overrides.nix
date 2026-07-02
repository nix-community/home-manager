{ config, ... }:

{
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;

    historyWidget = {
      command = "global-history";
      bash.command = "";
    };

    fileWidget.bash.command = "$HOME/bin/files";

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

  programs.bash.enable = true;

  nmt.script = ''
    assertFileRegex home-files/.bashrc \
      'export FZF_CTRL_R_COMMAND='

    assertFileContains home-files/.bashrc \
      'export FZF_CTRL_T_COMMAND="$HOME/bin/files"'

    overrideLine=$(grep -n 'export FZF_CTRL_R_COMMAND=' "$TESTED/home-files/.bashrc" | head -n1 | cut -d: -f1)
    sourceLine=$(grep -n 'fzf.*--bash' "$TESTED/home-files/.bashrc" | head -n1 | cut -d: -f1)

    if [[ -z "$overrideLine" || -z "$sourceLine" || "$overrideLine" -ge "$sourceLine" ]]; then
      fail "bash fzf widget override must appear before fzf initialization"
    fi
  '';
}
