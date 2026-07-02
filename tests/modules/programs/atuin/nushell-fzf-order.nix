{ config, pkgs, ... }:

{
  programs = {
    atuin = {
      enable = true;
      enableNushellIntegration = true;

      package = config.lib.test.mkStubPackage {
        name = "atuin";
        buildScript = ''
          mkdir -p $out/bin
          cat > $out/bin/atuin <<'EOF'
          #!/bin/sh
          echo "Stub atuin"
          EOF
          chmod +x $out/bin/atuin
        '';
      };
    };

    fzf = {
      enable = true;
      enableNushellIntegration = true;

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

    nushell.enable = true;
  };

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
      assertFileContent "$(normalizeStorePaths "${nushellConfigFile}")" ${builtins.toFile "nushell-fzf-atuin-order-expected.nu" ''
        source /nix/store/00000000000000000000000000000000-nushell-fzf-integration.nu

        source /nix/store/00000000000000000000000000000000-atuin-nushell-config.nu

      ''}
    '';
}
