{
  config,
  lib,
  pkgs,
  ...
}:
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
    let
      cfg = config.services.plex-mpv-shim;
      configPath = "${config.xdg.configHome}/plex-mpv-shim/conf.json";
      servicePath = "home-files/${lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome}/systemd/user/plex-mpv-shim.service";
    in
    assert
      config.home.activation.plexMpvShimSettingsActivation.data == lib.hm.generators.mkImpureConfigMerger
        {
          inherit pkgs;
          format = "json";
          empty = "{}";
          jqOperation = "$dynamic * $static";
          path = configPath;
          staticSettings = (pkgs.formats.json { }).generate "plex-mpv-shim-conf.json" cfg.settings;
        };
    assert builtins.elem "linkGeneration" config.home.activation.plexMpvShimSettingsActivation.after;
    assert builtins.elem "reloadSystemd" config.home.activation.plexMpvShimSettingsActivation.before;
    ''
      assertPathNotExists home-files/.config/plex-mpv-shim/conf.json
      assertPathNotExists home-files/${lib.removePrefix "${config.home.homeDirectory}/" configPath}
      assertFileContains activate '${configPath}'
      assertFileContains ${servicePath} 'ExecStart=${cfg.package}/bin/plex-mpv-shim'

      generated="$(grep -o '/nix/store/[^ ]*-plex-mpv-shim-conf.json' "$TESTED/activate" | sort -u)"
      assertFileContent "$generated" ${./basic-configuration.json}
      assertFileContains ${servicePath} \
        "X-Restart-Triggers=$generated"
    '';
}
