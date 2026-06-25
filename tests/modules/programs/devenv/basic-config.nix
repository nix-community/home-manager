{ config, pkgs, ... }:
{
  programs = {
    devenv = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      package = config.lib.test.mkStubPackage {
        name = "devenv";
        buildScript = ''
          mkdir -p $out/bin
          cat > $out/bin/devenv << 'EOF'
          #! /bin/sh
          echo "Stub called with args $@"
          EOF
          chmod +x $out/bin/devenv
        '';
      };
    };
    bash.enable = true;
    fish.enable = true;
    nushell.enable = true;
    zsh.enable = true;
  };

  nmt.script =
    let
      nushellConfigFile =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell/config.nu"
        else
          "home-files/.config/nushell/config.nu";
    in
    # Bash
    ''
      assertFileRegex home-files/.bashrc \
        'eval.*devenv hook bash'

      # Test zsh integration
      assertFileRegex home-files/.zshrc \
        'eval.*devenv hook zsh'

      # Test fish integration (enabled by default)
      assertFileRegex home-files/.config/fish/config.fish \
        'devenv hook fish.*source'

      # Test nushell integration
      assertFileExists "${nushellConfigFile}"
      assertFileRegex "${nushellConfigFile}" 'source /nix/store.*devenv-nushell-config.nu'

    '';
}
