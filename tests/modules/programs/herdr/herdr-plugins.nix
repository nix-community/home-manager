{
  config,
  lib,
  pkgs,
  ...
}:
let
  # herdr's own plugin smoke fixture, packaged so `plugin link` sees a
  # canonical nix-store manifest path.
  packagePlugin = pkgs.runCommand "herdr-smoke-plugin" { } ''
    mkdir -p $out
    cp ${./herdr-plugin.toml} $out/herdr-plugin.toml
  '';
  herdrBin = lib.getExe pkgs.herdr;
  jqBin = lib.getExe pkgs.jq;
  activationScript = pkgs.writeScript "activation" config.home.activation.herdrPlugins.data;

  # Registry seeds. herdr stores registrations in plugins.json; the server
  # reloads the file on every `plugin list`, so seeding is enough to exercise
  # the module against a live server.
  staleOld = {
    plugin_id = "stale.old";
    name = "Stale Old";
    version = "0.1.0";
    min_herdr_version = "0.6.10";
    manifest_path = "/nix/store/00000000000000000000000000000000-stale/herdr-plugin.toml";
    plugin_root = "/nix/store/00000000000000000000000000000000-stale";
    enabled = true;
  };
  githubTool = {
    plugin_id = "github.tool";
    name = "Github Tool";
    version = "0.1.0";
    min_herdr_version = "0.6.10";
    manifest_path = "/home/hm-user/.config/herdr/plugins/github/owner-repo-abcdef/github-tool/herdr-plugin.toml";
    plugin_root = "/home/hm-user/.config/herdr/plugins/github/owner-repo-abcdef/github-tool";
    enabled = true;
    source = {
      kind = "github";
      owner = "owner";
      repo = "repo";
      subdir = "github-tool";
      managed_path = "/home/hm-user/.config/herdr/plugins/github/owner-repo-abcdef/github-tool";
    };
  };
  smokeAt = enabled: manifest_path: plugin_root: {
    plugin_id = "example.smoke";
    name = "Smoke Plugin";
    version = "0.1.0";
    min_herdr_version = "0.6.10";
    inherit manifest_path plugin_root enabled;
  };
  seedRegistry = seed: ''
    cat >"$XDG_CONFIG_HOME/herdr/plugins.json" <<EOF
    ${builtins.toJSON seed}
    EOF
  '';
in
{
  programs.herdr = {
    enable = true;
    package = pkgs.herdr;

    plugins = {
      "example.smoke" = {
        package = packagePlugin;
      };
    };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    export HOME=$TMPDIR/hm-user
    export XDG_CONFIG_HOME=$TMPDIR/xdg-config
    export XDG_STATE_HOME=$TMPDIR/xdg-state
    export XDG_CACHE_HOME=$TMPDIR/xdg-cache
    export HERDR_SOCKET_PATH=$TMPDIR/herdr.sock
    mkdir -p "$HOME" "$XDG_CONFIG_HOME/herdr"

    # The generated activation script must diff canonical nix-store manifests
    # and drive the real herdr binary (the whitelisted pkgs.herdr).
    assertFileContains ${activationScript} "${herdrBin} plugin list --json"
    assertFileContains ${activationScript} ".result.plugins[]?"
    assertFileContains ${activationScript} 'store "/nix/store/"'
    assertFileContains ${activationScript} "startswith(\$store)"
    assertFileContains ${activationScript} 'plugin unlink "$id" >/dev/null 2>&1 || true'
    assertFileContains ${activationScript} 'plugin link "$manifest" >/dev/null 2>&1 || true'
    assertFileContains ${activationScript} '($desired - [.result.plugins[]?.manifest_path?])[]'
    assertFileContains ${activationScript} '"${packagePlugin}/herdr-plugin.toml"'

    # Scenario A: first activation against a live headless herdr server. The
    # seed holds a stale store plugin, a plugin herdr installed itself under
    # its managed `github` directory, and the configured plugin registered at
    # an old store path (as if its package was updated).
    ${seedRegistry [
      staleOld
      githubTool
      (smokeAt true "/nix/store/00000000000000000000000000000000-herdr-smoke-plugin-old/herdr-plugin.toml"
        "/nix/store/00000000000000000000000000000000-herdr-smoke-plugin-old"
      )
    ]}

    "${herdrBin}" server >"$TMPDIR/herdr-server.log" 2>&1 &
    SRV=$!
    for _ in $(seq 1 100); do [ -S "$HERDR_SOCKET_PATH" ] && break; sleep 0.1; done
    [ -S "$HERDR_SOCKET_PATH" ] \
      || {
        cat "$TMPDIR/herdr-server.log" 2>/dev/null || true
        kill "$SRV" 2>/dev/null || true
        fail "herdr server did not start"
      }

    source ${activationScript}

    "${herdrBin}" plugin list --json 2>/dev/null \
      | ${jqBin} -r '.result.plugins[]?.plugin_id' >"$TMPDIR/plugins-after-a"
    grep -q '^example.smoke$' "$TMPDIR/plugins-after-a" \
      || fail "expected example.smoke to be registered after activation"
    grep -q '^github.tool$' "$TMPDIR/plugins-after-a" \
      || fail "expected github.tool to remain registered"
    grep -q '^stale.old$' "$TMPDIR/plugins-after-a" \
      && fail "expected stale.old to be unlinked"
    "${herdrBin}" plugin list --json 2>/dev/null \
      | ${jqBin} -r --arg p "${packagePlugin}/herdr-plugin.toml" \
        '.result.plugins[]? | select(.plugin_id == "example.smoke") | .manifest_path' \
      | grep -Fqx "${packagePlugin}/herdr-plugin.toml" \
      || fail "expected example.smoke to be linked at its canonical manifest"

    # Scenario B: a second activation must be a true no-op.
    BEFORE="$("${herdrBin}" plugin list --json 2>/dev/null)"
    source ${activationScript}
    AFTER="$("${herdrBin}" plugin list --json 2>/dev/null)"
    [ "$BEFORE" = "$AFTER" ] \
      || fail "expected the second activation to leave the registry unchanged"

    # Scenario C: a desired plugin the user disabled stays disabled.
    ${seedRegistry [
      githubTool
      (smokeAt false "${packagePlugin}/herdr-plugin.toml" "${packagePlugin}")
    ]}
    source ${activationScript}
    "${herdrBin}" plugin list --json 2>/dev/null \
      | ${jqBin} -r --arg p "${packagePlugin}/herdr-plugin.toml" \
        '.result.plugins[]? | select(.plugin_id == "example.smoke") | [.manifest_path == $p, (.enabled | not)] | all' \
      | grep -qx true \
      || fail "expected the disabled plugin to stay disabled at its canonical manifest"

    # Scenario D: with the server unreachable, `plugin link` still persists
    # offline while `plugin unlink` is deferred to the next activation.
    kill "$SRV" 2>/dev/null || true
    wait "$SRV" 2>/dev/null || true
    rm -f "$HERDR_SOCKET_PATH"

    ${seedRegistry [
      staleOld
      githubTool
    ]}
    source ${activationScript}

    "${herdrBin}" plugin list --json 2>/dev/null \
      | ${jqBin} -r '.result.plugins[]?.plugin_id' >"$TMPDIR/plugins-after-d"
    grep -q '^example.smoke$' "$TMPDIR/plugins-after-d" \
      || fail "expected example.smoke to be registered even without a running server"
    grep -q '^stale.old$' "$TMPDIR/plugins-after-d" \
      || fail "expected stale.old to stay registered while the server is unreachable"
    grep -Fq "${packagePlugin}/herdr-plugin.toml" "$XDG_CONFIG_HOME/herdr/plugins.json" \
      || fail "expected the offline link to be persisted to the registry"
    grep -Fq '"plugin_id": "stale.old"' "$XDG_CONFIG_HOME/herdr/plugins.json" \
      || fail "expected the deferred unlink to leave stale.old in the registry"
  '';
}
