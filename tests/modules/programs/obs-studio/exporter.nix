{
  lib,
  pkgs,
  realPkgs,
  ...
}:
let
  obsPackage = pkgs.runCommand "obs" { passthru = { }; } ''
    mkdir -p $out/bin $out/share/obs/obs-plugins
    printf '#!${pkgs.runtimeShell}\n' > $out/bin/obs
    chmod +x $out/bin/obs
  '';
in
{
  programs.obs-studio = {
    enable = true;
    package = obsPackage;
    tools.package = realPkgs.callPackage ../../../../tools/managed-config/package.nix { };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    export HOME=$TMPDIR/hm-user
    configDir="$TMPDIR/obs-studio"
    mkdir -p "$configDir/basic/profiles/Portable" "$configDir/basic/scenes" "$configDir/plugin_config/obs-websocket"

    cat > "$configDir/global.ini" <<'EOF'
    [General]
    MaxLogs=10
    LastVersion=536936449
    ProcessPriority=Normal
    EOF

    cat > "$configDir/user.ini" <<'EOF'
    [BasicWindow]
    geometry=runtime-state
    DockState=runtime-state

    [Basic]
    Profile=Portable
    SceneCollection=Streaming
    EOF

    cat > "$configDir/basic/profiles/Portable/basic.ini" <<'EOF'
    [AdvOut]
    RecFilePath=/home/hm-user/Videos
    Encoder=obs_x264

    [Output]
    FilenameFormatting=%CCYY-%MM-%DD %hh-%mm-%ss
    EOF

    cat > "$configDir/basic/scenes/Streaming.json" <<'EOF'
    {
      "name": "Streaming",
      "sources": [
        {
          "name": "desktop",
          "id": "pipewire-screen-capture-source",
          "settings": {
            "RestoreToken": "secret-token",
            "ShowCursor": true
          }
        }
      ]
    }
    EOF

    cat > "$configDir/plugin_config/obs-websocket/config.json" <<'EOF'
    {
      "server_port": 4455,
      "server_password": "secret"
    }
    EOF

    tool="$TESTED/home-path/bin/hermesix"
    generic_compat="$TESTED/home-path/bin/hm-managed-config"
    old_tool="$TESTED/home-path/bin/obs-studio-sync"
    compat="$TESTED/home-path/bin/obs-studio-export-to-nix"

    "$tool" obs export-to-nix "$configDir" > "$TMPDIR/export.nix"
    "$generic_compat" obs export-to-nix "$configDir" > "$TMPDIR/export-generic-compat.nix"
    cmp "$TMPDIR/export.nix" "$TMPDIR/export-generic-compat.nix"
    "$compat" "$configDir" > "$TMPDIR/export-compat.nix"
    cmp "$TMPDIR/export.nix" "$TMPDIR/export-compat.nix"
    "$old_tool" export-to-nix "$configDir" > "$TMPDIR/export-old-tool.nix"
    cmp "$TMPDIR/export.nix" "$TMPDIR/export-old-tool.nix"

    assertFileContains "$TMPDIR/export.nix" '"MaxLogs" = "10";'
    assertFileContains "$TMPDIR/export.nix" '"SceneCollection" = "Streaming";'
    assertFileContains "$TMPDIR/export.nix" '"FilenameFormatting" = "%CCYY-%MM-%DD %hh-%mm-%ss";'
    assertFileContains "$TMPDIR/export.nix" '"ShowCursor" = true;'
    assertFileContains "$TMPDIR/export.nix" 'server_port'
    assertFileNotRegex "$TMPDIR/export.nix" 'LastVersion|geometry|DockState|RecFilePath|RestoreToken|server_password|secret-token'

    mkdir -p "$TMPDIR/manifest-source" "$TMPDIR/live-config" "$TMPDIR/plugin-src"
    cat > "$TMPDIR/manifest-source/global.ini" <<'EOF'
    [General]
    MaxLogs=12
    EOF
    hash="$(${pkgs.coreutils}/bin/sha256sum "$TMPDIR/manifest-source/global.ini" | cut -d ' ' -f 1)"
    cat > "$TMPDIR/manifest.json" <<EOF
    {
      "version": 1,
      "files": [
        {
          "path": "global.ini",
          "source": "$TMPDIR/manifest-source/global.ini",
          "target": "$TMPDIR/live-config/global.ini",
          "sha256": "$hash",
          "kind": "ini",
          "origin": "settings.global"
        }
      ]
    }
    EOF

    set +e
    "$tool" diff --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live-config" > "$TMPDIR/diff.txt"
    diff_status=$?
    set -e
    test "$diff_status" -eq 1
    assertFileContains "$TMPDIR/diff.txt" 'missing global.ini'
    set +e
    "$tool" diff --json --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live-config" > "$TMPDIR/diff.json"
    diff_json_status=$?
    set -e
    test "$diff_json_status" -eq 1
    ${pkgs.jq}/bin/jq -e '. == [{"status":"missing","path":"global.ini"}]' "$TMPDIR/diff.json" >/dev/null
    set +e
    "$tool" sync --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live-config" > "$TMPDIR/sync-dry-run.txt"
    sync_status=$?
    set -e
    test "$sync_status" -eq 1
    assertPathNotExists "$TMPDIR/live-config/global.ini"
    assertFileContains "$TMPDIR/sync-dry-run.txt" 'dry-run'
    "$tool" sync --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live-config" --apply
    assertFileContains "$TMPDIR/live-config/global.ini" "MaxLogs=12"
    "$tool" validate --manifest "$TMPDIR/manifest.json" --config-dir "$TMPDIR/live-config" > "$TMPDIR/validate.txt"
    assertFileContains "$TMPDIR/validate.txt" 'manifest ok'

    "$tool" redact "$configDir/basic/scenes/Streaming.json" --format json > "$TMPDIR/redacted.json"
    assertFileContains "$TMPDIR/redacted.json" '"ShowCursor": true'
    assertFileNotRegex "$TMPDIR/redacted.json" 'RestoreToken|secret-token'

    cat > "$TMPDIR/plugin-src/source.c" <<'EOF'
    static struct obs_source_info demo_source = { .id = "demo_source" };
    obs_data_set_default_string(settings, "demo_key", "value");
    obs_properties_add_text(props, "demo_key", "Demo", OBS_TEXT_DEFAULT);
    obs_register_source(&demo_source);
    EOF
    "$tool" obs plugin-inspect --source-dir "$TMPDIR/plugin-src" > "$TMPDIR/plugin-evidence.json"
    assertFileContains "$TMPDIR/plugin-evidence.json" 'obs_source_info'
    assertFileContains "$TMPDIR/plugin-evidence.json" 'obs_data_set_default_string'
    assertFileContains "$TMPDIR/plugin-evidence.json" 'obs_properties_add_text'
    ${pkgs.jq}/bin/jq -e '.source_ids[0].key == "demo_source" and .setting_defaults[0].key == "demo_key"' "$TMPDIR/plugin-evidence.json" >/dev/null
    "$tool" obs plugin-inspect verify --evidence ${../../../../tools/managed-config/plugin-schemas/local-test-plugin.json} --source-dir "$TMPDIR/plugin-src" > "$TMPDIR/plugin-verify.txt"
    assertFileContains "$TMPDIR/plugin-verify.txt" 'plugin evidence ok'
  '';
}
