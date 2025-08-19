{ pkgs, ... }:

{
  programs.mypy = {
    enable = true;

    package = pkgs.mypy;

    settings = {
      mypy = {
        warn_return_any = true;
        warn_unused_configs = true;
      };

      "mypy-mycode.foo.*" = {
        disallow_untyped_defs = true;
      };

      "mypy-mycode.bar".warn_return_any = false;

      "mypy-somelibrary".ignore_missing_imports = true;
    };
  };

  nmt.script =
    let
      configFile = "home-files/.config/mypy/config";
    in
    ''
      assertFileExists ${configFile}
      assertFileContent ${configFile} \
        ${pkgs.writeText "settings-expected" ''
          [mypy]
          warn_return_any=true
          warn_unused_configs=true

          [mypy-mycode.bar]
          warn_return_any=false

          [mypy-mycode.foo.*]
          disallow_untyped_defs=true

          [mypy-somelibrary]
          ignore_missing_imports=true
        ''}
    '';
}
