# Test custom keymap functionality
{ config, ... }:

{
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    mutableUserDebug = false;
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

  nmt.script =
    let
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

      settingsPath = ".config/zed/debug.json";
    in
    ''
      assertFileExists "home-files/${settingsPath}"
      assertFileContent "home-files/${settingsPath}" "${expectedContent}"
    '';
}
