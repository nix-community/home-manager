{
  config,
  lib,
  ...
}:

{
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    userDebug = [
      {
        label = "PHP: Listen to Xdebug";
        adapter = "Xdebug";
        request = "launch";
        port = 9003;
      }
      {
        label = "PHP: Debug this test";
        adapter = "Xdebug";
        request = "launch";
        program = "vendor/bin/phpunit";
        args = [
          "--filter"
          "$ZED_SYMBOL"
        ];
      }
    ];
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      preexistingDebug = builtins.toFile "preexisting.json" "";

      expectedContent = builtins.toFile "expected.json" ''
        [
          {
            "adapter": "Xdebug",
            "label": "PHP: Listen to Xdebug",
            "port": 9003,
            "request": "launch"
          },
          {
            "adapter": "Xdebug",
            "args": [
              "--filter",
              "$ZED_SYMBOL"
            ],
            "label": "PHP: Debug this test",
            "program": "vendor/bin/phpunit",
            "request": "launch"
          }
        ]
      '';

      debugPath = ".config/zed/debug.json";
    in
    config.lib.test.runMutableConfigTest {
      files.${debugPath} = preexistingDebug;
      expected.${debugPath} = expectedContent;
    };
}
