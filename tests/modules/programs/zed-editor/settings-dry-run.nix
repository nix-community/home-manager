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
    userSettings = {
      theme = "XY-Zed";
      vim_mode = false;
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      preexistingSettings = builtins.toFile "preexisting.json" ''
        {
          "theme": "Default"
        }
      '';

      expectedContent = builtins.toFile "expected.json" ''
        {
          "theme": "XY-Zed",
          "vim_mode": false
        }
      '';

      settingsPath = ".config/zed/settings.json";
      corruptedSettings = builtins.toFile "corrupted.json" ''
        { not valid json
      '';
      activationScript = pkgs.writeScript "activation" config.home.activation.zedSettingsActivation.data;
      mkActivation = name: ''
        substitute ${activationScript} $TMPDIR/${name} --subst-var TMPDIR
        chmod +x $TMPDIR/${name}
      '';
    in
    ''
      export HOME=$TMPDIR/hm-user

      # Simulate preexisting settings
      mkdir -p $HOME/.config/zed
      cat ${preexistingSettings} > $HOME/${settingsPath}

      ${mkActivation "activate"}

      # Dry-run must leave the existing settings untouched and must not fail
      # with an unbound variable error.
      export DRY_RUN=1
      $TMPDIR/activate > $TMPDIR/dry-output
      unset DRY_RUN
      assertFileContent "$HOME/${settingsPath}" "${preexistingSettings}"
      grep 'Would merge Nix-generated config into' $TMPDIR/dry-output

      # A live run applies the Nix-generated settings on top.
      $TMPDIR/activate
      assertFileContent "$HOME/${settingsPath}" "${expectedContent}"

      # Verbose mode logs the merge message.
      ${mkActivation "activate-verbose"}
      export VERBOSE=1
      $TMPDIR/activate-verbose > $TMPDIR/verbose-output
      unset VERBOSE
      grep 'Merging Nix-generated config into' $TMPDIR/verbose-output

      # Without verbose, no merge message is logged.
      $TMPDIR/activate > $TMPDIR/quiet-output
      test ! -s $TMPDIR/quiet-output

      # A live run must preserve the permissions of an existing file.
      chmod 600 $HOME/${settingsPath}
      $TMPDIR/activate
      currentMode="$(stat -c '%a' $HOME/${settingsPath})"
      test "$currentMode" = 600 || {
        echo "Expected mode 600, got $currentMode"
        exit 1
      }

      # A corrupted existing file must fail activation loudly instead of
      # silently overwriting it with the generated defaults.
      echo '{ not valid json' > $HOME/${settingsPath}
      if $TMPDIR/activate > /dev/null 2>&1; then
        echo "Activation unexpectedly succeeded on a corrupted config file"
        exit 1
      fi
      assertFileContent "$HOME/${settingsPath}" "${corruptedSettings}"
    '';
}
