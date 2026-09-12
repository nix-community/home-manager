{ config, pkgs, ... }:

let
  dummyPkg = pkgs.hello;
in
{
  services.radicle.node = {
    enable = true;
    environment = {
      OMITTED_NULL = null;
      STR_VAL = "hello";
      PATH_VAL = /tmp/some-path;
      PACKAGE_VAL = dummyPkg;
    };
  };

  test.stubs.radicle-node = {
    buildScript = ''
      mkdir -p "$out/bin"
      cat > "$out/bin/rad" << 'EOF'
      #!/bin/sh
      exit 0
      EOF
      chmod +x "$out/bin/rad"
    '';
  };

  nmt.script =
    let
      expectedEnv = [
        "PACKAGE_VAL=${dummyPkg}"
        "PATH_VAL=/tmp/some-path"
        "STR_VAL=hello"
        "PATH=${pkgs.gitMinimal}/bin"
      ];
      actualEnv = config.systemd.user.services.radicle-node.Service.Environment;
    in
    ''
      assertFileContent \
        ${pkgs.writeText "actual-env" (builtins.toJSON actualEnv)} \
        ${pkgs.writeText "expected-env" (builtins.toJSON expectedEnv)}
    '';
}
