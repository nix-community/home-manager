{ config, ... }:

{
  programs = {
    fnox = {
      enable = true;
      package = config.lib.test.mkStubPackage {
        name = "custom-fnox";
        buildScript = ''
          mkdir -p "$out/bin"
          cat > "$out/bin/fnox" <<'EOF'
          #!/bin/sh
          if [ "$1" = activate ] && [ "$2" = nu ]; then
            echo "# $0 $1 $2"
          fi
          EOF
          chmod +x "$out/bin/fnox"
        '';
      };
      settings = {
        env = "exec";
        if_missing = "warn";
        prompt_auth = false;
        daemon.enabled = false;
      };
    };

    bash.enable = true;
    fish.enable = true;
    nushell.enable = true;
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/fnox/config.toml
    assertFileContent home-files/.config/fnox/config.toml ${./expected.toml}

    assertFileRegex home-files/.bashrc \
      '/nix/store/[^/]*-custom-fnox/bin/fnox activate bash'
    assertFileRegex home-files/.config/fish/config.fish \
      '/nix/store/[^/]*-custom-fnox/bin/fnox activate fish \| source'
    assertFileRegex home-files/.zshrc \
      '/nix/store/[^/]*-custom-fnox/bin/fnox activate zsh'

    assertFileRegex home-files/.config/nushell/config.nu \
      'source /nix/store/[^/]*-fnox-nushell-integration.nu'
    nushellIntegration=$(sed -n \
      's|^source \(/nix/store/[^/]*-fnox-nushell-integration.nu\)$|\1|p' \
      "$(_abs home-files/.config/nushell/config.nu)")
    assertFileRegex "$nushellIntegration" \
      '^# /nix/store/[^/]*-custom-fnox/bin/fnox activate nu$'
  '';
}
