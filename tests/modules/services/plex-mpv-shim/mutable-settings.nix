{ config, ... }:
{
  services.plex-mpv-shim = {
    enable = true;
    mutableSettings = true;
    settings = {
      allow_http = false;
      auto_play = true;
      player_name = "Home Manager";
    };
  };

  # The merge itself is covered by the mkImpureConfigMerger tests; this checks
  # what the module wires up around it.
  nmt.script =
    assert builtins.elem "linkGeneration" config.home.activation.plexMpvShimSettingsActivation.after;
    assert builtins.elem "reloadSystemd" config.home.activation.plexMpvShimSettingsActivation.before;
    ''
      assertPathNotExists home-files/.config/plex-mpv-shim/conf.json
      assertFileContains activate '/home/hm-user/.config/plex-mpv-shim/conf.json'

      generated="$(grep -o '/nix/store/[^ ]*-plex-mpv-shim-conf.json' "$TESTED/activate" | sort -u)"
      assertFileContent "$generated" ${./basic-configuration.json}
      assertFileContains home-files/.config/systemd/user/plex-mpv-shim.service \
        "X-Restart-Triggers=$generated"
    '';
}
