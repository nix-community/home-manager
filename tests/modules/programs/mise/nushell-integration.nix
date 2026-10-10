{
  miseVersion ? "2026.9.2",
}:
{
  config,
  lib,
  realPkgs,
  ...
}:
let
  unsupported = lib.versionAtLeast miseVersion "2026.9.0" && lib.versionOlder miseVersion "2026.9.2";
  runtimeActivation = lib.versionAtLeast miseVersion "2026.9.0";
  stubMise = config.lib.test.mkStubPackage {
    name = "mise";
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/mise
      chmod +x $out/bin/mise
    '';
  };
  pathTest = realPkgs.writeShellScript "hm-mise-path-test" ''
    echo runtime-path-ok
  '';
in
{
  programs = {
    mise = {
      # Exercise both sides of the version gate with the locked executable.
      package =
        (
          if config.test.enableBig then
            realPkgs.mise
          else
            stubMise
        )
        // {
          version = miseVersion;
        };
      enable = true;
      enableNushellIntegration = true;
    };

    nushell = {
      enable = true;
      configDir = "${config.xdg.configHome}/custom-nushell";
    };
  };

  test.asserts.assertions.expected = lib.optional unsupported "programs.mise: Nushell integration with mise 2026.9.0 or 2026.9.1 has a broken PATH prelude; upgrade mise to 2026.9.2 or newer.";

  nmt.script =
    lib.optionalString (config.test.enableBig && !unsupported) ''
      export HOME=$TMPDIR/hm-user
      export XDG_CONFIG_HOME=$HOME/.config
      export XDG_CACHE_HOME="$HOME/custom cache"
      export MISE_DATA_DIR=$TMPDIR/mise-data
      export MISE_CACHE_DIR=$TMPDIR/mise-cache
      export MISE_STATE_DIR=$TMPDIR/mise-state
      export MISE_OFFLINE=1
      export HM_MISE_TEST_BIN=$TMPDIR/runtime-bin
      mkdir -p "$HOME/.config/custom-nushell" "$HM_MISE_TEST_BIN"
      ln -s "$TESTED"/home-files/.config/custom-nushell/*.nu "$HOME/.config/custom-nushell/"
      ${lib.optionalString (!runtimeActivation) ''
        touch "$HOME/.config/custom-nushell/env.nu"
      ''}
      cp ${pathTest} "$HM_MISE_TEST_BIN/hm-mise-path-test"
      export PATH="$HM_MISE_TEST_BIN:$PATH"

      test ! -e "$XDG_CACHE_HOME" || exit 1

      run_nushell() {
        ${lib.getExe realPkgs.nushell} \
          --config "$HOME/.config/custom-nushell/config.nu" \
          --env-config "$HOME/.config/custom-nushell/env.nu" --login --commands '
          use std/assert

          def check-path [] {
            assert ($env.HM_MISE_TEST_BIN in $env.PATH)
            assert ((^hm-mise-path-test) == "runtime-path-ok")
          }

          assert not ($nu.default-config-dir | path exists)
          ${lib.optionalString runtimeActivation ''
            assert ($nu.cache-dir | path join "home-manager-mise" | path exists)
            assert not ($nu.cache-dir | path join "home-manager-mise" $"mise-($nu.pid).nu" | path exists)
          ''}
          assert (($env.config.hooks.pre_prompt | length) > 0)
          check-path
          for hook in $env.config.hooks.pre_prompt {
            do $hook.code
          }
          check-path
        '
      }

      run_nushell || exit 1
      pids=()
      for i in {1..8}; do
        (
          export HM_MISE_TEST_BIN=$TMPDIR/runtime-bin-$i
          mkdir -p "$HM_MISE_TEST_BIN"
          cp ${pathTest} "$HM_MISE_TEST_BIN/hm-mise-path-test"
          export PATH="$HM_MISE_TEST_BIN:$PATH"
          run_nushell
        ) &
        pids+=("$!")
      done
      for pid in "''${pids[@]}"; do
        wait "$pid" || exit 1
      done
    ''
    + lib.optionalString runtimeActivation ''
      assertFileContains home-files/.config/custom-nushell/env.nu \
        '${lib.getExe config.programs.mise.package} activate nu'
      assertFileContains home-files/.config/custom-nushell/env.nu \
        'save ($nu.cache-dir | path join "home-manager-mise" $"mise-($nu.pid).nu") --force'
      assertFileContains home-files/.config/custom-nushell/config.nu \
        'use ($nu.cache-dir | path join "home-manager-mise" $"mise-($nu.pid).nu")'
      assertFileContains home-files/.config/custom-nushell/config.nu \
        'rm ($nu.cache-dir | path join "home-manager-mise" $"mise-($nu.pid).nu")'
    ''
    + lib.optionalString (!runtimeActivation) ''
      assertPathNotExists home-files/.config/custom-nushell/env.nu
      assertFileRegex home-files/.config/custom-nushell/config.nu \
        'use /nix/store/.*-mise-nushell-config.nu'
    '';
}
