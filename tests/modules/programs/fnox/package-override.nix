{ config, ... }:

{
  programs.fnox = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "fnox";
      buildScript = ''
        mkdir -p "$out/bin"
        cat > "$out/bin/fnox" <<'EOF'
        #!/bin/sh
        # fnox package override
        EOF
        chmod +x "$out/bin/fnox"
      '';
    };
  };

  home.shell.enableShellIntegration = false;

  nmt.script = ''
    assertFileExists home-path/bin/fnox
    assertFileContains home-path/bin/fnox '# fnox package override'
  '';
}
