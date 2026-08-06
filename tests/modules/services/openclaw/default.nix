_:

{
  openclaw-basic =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      fakeOpenclaw = pkgs.writeShellScriptBin "openclaw" ''
        echo fake-openclaw "$@"
      '';
    in
    {
      services.openclaw = {
        enable = true;
        package = fakeOpenclaw;
        gateway.port = 18789;
        settings = {
          gateway = {
            port = 18789;
            bind = "loopback";
          };
          runtime.declared = true;
        };
      };

      home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

      nmt.script =
        let
          preexistingSettings = builtins.toFile "preexisting-openclaw.json" ''
            {
              "gateway": {
                "port": 19999,
                "runtimeOnly": true
              },
              "runtime": {
                "live": true
              }
            }
          '';

          expectedSettings = builtins.toFile "expected-openclaw.json" ''
            {
              "gateway": {
                "bind": "loopback",
                "port": 18789,
                "runtimeOnly": true
              },
              "runtime": {
                "declared": true,
                "live": true
              }
            }
          '';

          activationScript = pkgs.writeScript "activation" config.home.activation.openclawSettings.data;
        in
        ''
          assertFileExists home-path/bin/openclaw

          ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
            serviceFile=home-files/.config/systemd/user/openclaw-gateway.service
            serviceFile=$(normalizeStorePaths "$serviceFile")
            assertFileRegex "$serviceFile" '^ExecStart=.*/bin/openclaw gateway run --port 18789 --tailscale off$'
            assertFileRegex "$serviceFile" '^WorkingDirectory=/@TMPDIR@/hm-user$'
            assertFileRegex "$serviceFile" '^Restart=always$'
          ''}

          ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
            serviceFile=LaunchAgents/org.nix-community.home.openclaw-gateway.plist
            serviceFile=$(normalizeStorePaths "$serviceFile")
            assertFileRegex "$serviceFile" '<string>org.nix-community.home.openclaw-gateway</string>'
            assertFileRegex "$serviceFile" '<key>KeepAlive</key>'
            assertFileRegex "$serviceFile" '<key>Crashed</key>'
            assertFileRegex "$serviceFile" '<true/>'
            assertFileRegex "$serviceFile" '<key>SuccessfulExit</key>'
            assertFileRegex "$serviceFile" '<false/>'
            assertFileRegex "$serviceFile" '<key>ProcessType</key>'
            assertFileRegex "$serviceFile" '<string>Background</string>'
            assertFileRegex "$serviceFile" '<key>ProgramArguments</key>'
            assertFileRegex "$serviceFile" '<string>/bin/sh</string>'
            assertFileRegex "$serviceFile" '<string>-c</string>'
            assertFileRegex "$serviceFile" '<string>/bin/wait4path /nix/store &amp;&amp; exec .*/bin/openclaw gateway run --port 18789 --tailscale off</string>'
            assertFileRegex "$serviceFile" '<key>RunAtLoad</key>'
            assertFileRegex "$serviceFile" '<key>WorkingDirectory</key>'
            assertFileRegex "$serviceFile" '<string>/@TMPDIR@/hm-user</string>'
          ''}

          export HOME=$TMPDIR/hm-user
          configPath=$HOME/.openclaw/openclaw.json

          mkdir -p "$(dirname "$configPath")"
          cat ${preexistingSettings} > "$configPath"

          substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
          chmod +x $TMPDIR/activate
          $TMPDIR/activate

          ${pkgs.jq}/bin/jq -S . "$configPath" > $TMPDIR/actual.json
          ${pkgs.jq}/bin/jq -S . ${expectedSettings} > $TMPDIR/expected.json
          assertFileContent $TMPDIR/actual.json $TMPDIR/expected.json

          $TMPDIR/activate
          ${pkgs.jq}/bin/jq -S . "$configPath" > $TMPDIR/actual-idempotent.json
          assertFileContent $TMPDIR/actual-idempotent.json $TMPDIR/expected.json
        '';
    };

  openclaw-immutable-settings =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      fakeOpenclaw = pkgs.writeShellScriptBin "openclaw" ''
        echo fake-openclaw "$@"
      '';
    in
    {
      services.openclaw = {
        enable = true;
        package = fakeOpenclaw;
        mutableSettings = false;
        settings = {
          gateway = {
            port = 18789;
            bind = "loopback";
          };
          runtime.declared = true;
        };
      };

      home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

      nmt.script =
        let
          preexistingSettings = builtins.toFile "preexisting-openclaw.json" ''
            {
              "gateway": {
                "port": 19999,
                "runtimeOnly": true
              },
              "runtime": {
                "live": true
              }
            }
          '';

          expectedSettings = builtins.toFile "expected-openclaw.json" ''
            {
              "gateway": {
                "bind": "loopback",
                "port": 18789
              },
              "runtime": {
                "declared": true
              }
            }
          '';

          activationScript = pkgs.writeScript "activation" config.home.activation.openclawSettings.data;
        in
        ''
          export HOME=$TMPDIR/hm-user
          configPath=$HOME/.openclaw/openclaw.json

          mkdir -p "$(dirname "$configPath")"
          cat ${preexistingSettings} > "$configPath"

          substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
          chmod +x $TMPDIR/activate
          $TMPDIR/activate

          ${pkgs.jq}/bin/jq -S . "$configPath" > $TMPDIR/actual.json
          ${pkgs.jq}/bin/jq -S . ${expectedSettings} > $TMPDIR/expected.json
          assertFileContent $TMPDIR/actual.json $TMPDIR/expected.json
        '';
    };

  openclaw-mutable-symlink-settings =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      fakeOpenclaw = pkgs.writeShellScriptBin "openclaw" ''
        echo fake-openclaw "$@"
      '';
    in
    {
      services.openclaw = {
        enable = true;
        package = fakeOpenclaw;
        settings = {
          gateway.port = 18789;
          runtime.declared = true;
        };
      };

      home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

      nmt.script =
        let
          preexistingSettings = builtins.toFile "preexisting-openclaw.json" ''
            {
              "gateway": {
                "runtimeOnly": true
              },
              "runtime": {
                "live": true
              }
            }
          '';

          expectedSettings = builtins.toFile "expected-openclaw.json" ''
            {
              "gateway": {
                "port": 18789,
                "runtimeOnly": true
              },
              "runtime": {
                "declared": true,
                "live": true
              }
            }
          '';

          activationScript = pkgs.writeScript "activation" config.home.activation.openclawSettings.data;
        in
        ''
          export HOME=$TMPDIR/hm-user
          configPath=$HOME/.openclaw/openclaw.json
          externalPath=$TMPDIR/external-openclaw.json

          mkdir -p "$(dirname "$configPath")"
          cat ${preexistingSettings} > "$externalPath"
          ln -s "$externalPath" "$configPath"

          substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
          chmod +x $TMPDIR/activate
          $TMPDIR/activate

          if [ -L "$configPath" ]; then
            fail "expected activation to replace symlinked OpenClaw config with a regular file"
          fi

          ${pkgs.jq}/bin/jq -S . "$configPath" > $TMPDIR/actual.json
          ${pkgs.jq}/bin/jq -S . ${expectedSettings} > $TMPDIR/expected.json
          assertFileContent $TMPDIR/actual.json $TMPDIR/expected.json
        '';
    };

  openclaw-settings-merge = ./settings-merge.nix;
}
