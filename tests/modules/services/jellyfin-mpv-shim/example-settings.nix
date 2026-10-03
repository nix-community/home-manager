{
  config,
  lib,
  pkgs,
  ...
}:
let
  staticSettings =
    (pkgs.formats.json { }).generate "jellyfin-mpv-shim-conf"
      config.services.jellyfin-mpv-shim.settings;
  configHome = lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome;
  activation = config.home.activation.jellyfinMpvShimSettingsActivation;
  merger = lib.hm.generators.mkImpureConfigMerger {
    inherit pkgs staticSettings;
    format = "json";
    empty = "{}";
    jqOperation = "$dynamic * $static";
    path = "${config.xdg.configHome}/jellyfin-mpv-shim/conf.json";
  };

in
{
  services.jellyfin-mpv-shim = {
    enable = true;

    settings = {
      allow_transcode_to_h265 = false;
      always_transcode = false;
      audio_output = "hdmi";
      auto_play = true;
      fullscreen = true;
      player_name = "mpv-shim";
    };

    mpvBindings = {
      WHEEL_UP = "seek 10";
      WHEEL_DOWN = "seek -10";
      "Alt+0" = "set window-scale 0.5";
    };

    mpvConfig = {
      force-window = true;
      ytdl-format = "bestvideo+bestaudio";
      cache-default = 4000000;
    };
  };

  nmt.script =
    assert activation.after == [ "linkGeneration" ];
    assert activation.before == [ "reloadSystemd" ];
    assert activation.data == merger;
    assert config.systemd.user.services.jellyfin-mpv-shim.Unit.X-Restart-Triggers == [ staticSettings ];
    ''
      # conf.json stays writable, so it is merged at activation instead of
      # linked; the merge itself is covered by the mkImpureConfigMerger tests.
      assertPathNotExists home-files/${configHome}/jellyfin-mpv-shim/conf.json
      assertFileContains activate ${lib.escapeShellArg "${config.xdg.configHome}/jellyfin-mpv-shim/conf.json"}
      assertFileContains home-files/${configHome}/systemd/user/jellyfin-mpv-shim.service 'X-Restart-Triggers=${staticSettings}'
      settings="$(grep -o '/nix/store/[^ ]*-jellyfin-mpv-shim-conf' "$TESTED/activate" | sort -u)"
      assertFileContent "$settings" ${./example-settings-expected-settings}
      assertFileContent \
         home-files/${configHome}/jellyfin-mpv-shim/mpv.conf \
         ${./example-settings-expected-config}
      assertFileContent \
         home-files/${configHome}/jellyfin-mpv-shim/input.conf \
         ${./example-settings-expected-bindings}

    '';
}
