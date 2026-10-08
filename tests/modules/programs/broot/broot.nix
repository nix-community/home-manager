{ config, ... }:

{
  programs.broot = {
    enable = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    package = (
      config.lib.test.mkStubPackage {
        name = "broot";
        # Mimic broot >= 1.51, whose nushell shell function is named `main`.
        buildScript = ''
          mkdir -p $out/bin
          cat > $out/bin/broot <<'EOF'
          #!/bin/sh
          echo 'export def --env main ['
          EOF
          chmod +x $out/bin/broot
        '';
        extraAttrs = {
          src = config.lib.test.mkStubPackage {
            name = "broot-src";
            buildScript = ''
              mkdir -p $out/resources/default-conf/
              echo test > $out/resources/default-conf/conf.hjson
            '';
          };
        };
      }
    );

    settings.modal = true;
  };

  programs.bash.enable = true;
  programs.nushell.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/broot/conf.hjson
    assertFileContains home-files/.config/broot/conf.hjson '"modal": true'
    assertFileRegex home-files/.bashrc 'source /nix/store/.*-br\.bash'
    assertFileRegex home-files/.config/nushell/config.nu \
      'source /nix/store/.*-br\.nushell'

    brNushell=$(
      sed -n 's/^[[:space:]]*source \(\/nix\/store\/.*-br\.nushell\)$/\1/p' \
        "$(_abs home-files/.config/nushell/config.nu)"
    )
    assertFileRegex "$brNushell" 'export def --env br \['
    assertFileNotRegex "$brNushell" 'export def --env main \['
  '';
}
