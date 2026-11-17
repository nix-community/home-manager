{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.cursor-agent = {
    enable = true;
    package = null;

    settings = {
      editor.vimMode = false;
      permissions = {
        allow = [
          "Shell(git diff:*)"
          "Shell(git log:*)"
        ];
        deny = [
          "Shell(rm:*)"
          "Read(.env*)"
        ];
      };
      network.useHttp1ForAgent = false;
      attribution = {
        attributeCommitsToAgent = false;
        attributePRsToAgent = false;
      };
    };

    rules = {
      code-style = ''
        ---
        description: "Code style guidelines"
        alwaysApply: true
        ---
        - Use consistent formatting
        - Follow language conventions
      '';
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      preexistingSettings = builtins.toFile "preexisting.json" (
        builtins.toJSON {
          version = 1;
          editor.vimMode = true;
          custom.agentSetting = "keep-me";
        }
      );

      expectedContent = builtins.toFile "expected.json" ''
        {
          "attribution": {
            "attributeCommitsToAgent": false,
            "attributePRsToAgent": false
          },
          "custom": {
            "agentSetting": "keep-me"
          },
          "editor": {
            "vimMode": false
          },
          "network": {
            "useHttp1ForAgent": false
          },
          "permissions": {
            "allow": [
              "Shell(git diff:*)",
              "Shell(git log:*)"
            ],
            "deny": [
              "Shell(rm:*)",
              "Read(.env*)"
            ]
          },
          "version": 1
        }
      '';

      configPath = ".cursor/cli-config.json";
      activationScript = pkgs.writeScript "activation" config.home.activation.cursorAgentCliConfig.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      # Simulate preexisting settings written by cursor agent
      mkdir -p $HOME/.cursor
      cat ${preexistingSettings} > $HOME/${configPath}

      # Run the activation script
      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate

      # Validate the merged settings (nix settings override, agent additions preserved)
      assertFileExists "$HOME/${configPath}"
      assertFileContent "$HOME/${configPath}" "${expectedContent}"

      # Test idempotency
      $TMPDIR/activate
      assertFileExists "$HOME/${configPath}"
      assertFileContent "$HOME/${configPath}" "${expectedContent}"

      # Validate rules still work via home.file
      assertFileExists home-files/.cursor/rules/code-style.md
      assertFileContent home-files/.cursor/rules/code-style.md \
        ${./expected-code-style.md}
    '';
}
