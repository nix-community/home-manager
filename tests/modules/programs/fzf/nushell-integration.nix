{ config, pkgs, ... }:

{
  programs.carapace = {
    enable = true;

    package = config.lib.test.mkStubPackage {
      name = "carapace";
      buildScript = ''
        mkdir -p $out/bin
        cat > $out/bin/carapace << 'EOF'
        #!/bin/sh
        echo "Stub carapace"
        EOF
        chmod +x $out/bin/carapace
      '';
    };
  };

  programs.fzf = {
    enable = true;
    enableNushellIntegration = true;

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

  programs.nushell.enable = true;

  nmt.script =
    let
      nushellConfigFile =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell/config.nu"
        else
          "home-files/.config/nushell/config.nu";
    in
    ''
      assertFileExists "${nushellConfigFile}"
      assertFileContent "$(normalizeStorePaths "${nushellConfigFile}")" ${builtins.toFile "nushell-fzf-integration-expected.nu" ''
        source /nix/store/00000000000000000000000000000000-carapace-nushell-config.nu

        source /nix/store/00000000000000000000000000000000-nushell-fzf-integration.nu

      ''}
    '';
}
