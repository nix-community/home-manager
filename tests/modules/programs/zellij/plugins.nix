{ config, ... }:
let
  zellijPackage = config.lib.test.mkStubPackage {
    name = "zellij";
    version = "0.44.3";
    extraAttrs.override =
      args:
      zellijPackage
      // {
        extraPackages = args.extraPackages or [ ];
      };
  };

  runtimeDep = config.lib.test.mkStubPackage {
    name = "just";
  };

  mkPlugin =
    name: deps:
    config.lib.test.mkStubPackage {
      name = "zellij-${name}";
      outPath = null;
      buildScript = ''
        echo wasm > "$out"
      '';
      extraAttrs = {
        pname = "zellij-${name}";
        runtimeDeps = deps;
      };
    };
in
{
  programs.zellij = {
    enable = true;
    package = zellijPackage;
    plugins = [
      (mkPlugin "foo" [ ])
      (mkPlugin "bar" [ ])
      (mkPlugin "baz" [ runtimeDep ])
    ];

    settings = {
      plugins.bar.foo = 123;
    };
  };

  nmt.script =
    assert builtins.elem runtimeDep config.programs.zellij.finalPackage.extraPackages;
    # sh
    ''
      assertFileExists home-files/.config/zellij/plugins/foo.wasm
      assertFileExists home-files/.config/zellij/plugins/bar.wasm
      assertFileExists home-files/.config/zellij/plugins/baz.wasm

      assertFileContent \
        home-files/.config/zellij/config.kdl \
        ${./plugins-config.kdl}
    '';
}
