{
  config,
  lib,
  pkgs,
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
      preexistingDebug = builtins.toFile "preexisting.json" ''
        [
          {
            "label": "Debug active Python file",
            "adapter": "Debugpy",
            "program": "$ZED_FILE",
            "request": "launch",
            "cwd": "$ZED_WORKTREE_ROOT"
          }
        ]
      '';

      expectedContent = builtins.toFile "expected.json" ''
        [
          {
            "label": "Debug active Python file",
            "adapter": "Debugpy",
            "program": "$ZED_FILE",
            "request": "launch",
            "cwd": "$ZED_WORKTREE_ROOT"
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
          },
          {
            "adapter": "Xdebug",
            "label": "PHP: Listen to Xdebug",
            "port": 9003,
            "request": "launch"
          }
        ]
      '';

      debugPath = ".config/zed/debug.json";
      activationScript = pkgs.writeScript "activation" config.home.activation.zedDebugActivation.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      # Simulate preexisting debug
      mkdir -p $HOME/.config/zed
      cat ${preexistingDebug} > $HOME/${debugPath}

      # Run the activation script
      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate

      # Validate the merged debug
      assertFileExists "$HOME/${debugPath}"
      assertFileContent "$HOME/${debugPath}" "${expectedContent}"

      # Test idempotency
      $TMPDIR/activate
      assertFileExists "$HOME/${debugPath}"
      assertFileContent "$HOME/${debugPath}" "${expectedContent}"
    '';
}
