{
  config = {
    programs.radicle.enable = true;

    test.stubs.radicle-node = {
      buildScript = ''
        mkdir -p "$out/bin"
        cat > "$out/bin/rad" << 'EOF'
        #!/bin/sh
        # Stub rad command that does nothing
        exit 0
        EOF
        chmod +x "$out/bin/rad"
      '';
    };

    nmt.script = ''
      assertFileContent \
        home-files/.radicle/config.json \
        ${./basic-configuration.json}
    '';
  };
}
