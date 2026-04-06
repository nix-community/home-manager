{ config, pkgs, ... }:
{
  programs = {
    devenv = {
      enable = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;

      package = config.lib.test.mkStubPackage {
        name = "devenv";
        version = "1.0.0";
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
      assertFileExists home-path/share/nushell/vendor/autoload/devenv.nu
      assertFileRegex home-path/share/nushell/vendor/autoload/devenv.nu \
        'Stub called with args.*hook nu'

    '';
}
