{
  config,
  lib,
  pkgs,
  ...
}:
let
  obsPackage = pkgs.runCommand "obs" { passthru = { }; } ''
    mkdir -p $out/bin $out/share/obs/obs-plugins
    printf '#!${pkgs.runtimeShell}\n' > $out/bin/obs
    chmod +x $out/bin/obs
  '';

  rawPlugin = pkgs.runCommand "raw-plugin" { } ''
    mkdir -p $out/lib/obs-plugins
    touch $out/lib/obs-plugins/raw-plugin.so
  '';

  namedPlugin = pkgs.runCommand "wlrobs" { } ''
    mkdir -p $out/lib/obs-plugins
    touch $out/lib/obs-plugins/wlrobs.so
  '';

  wrapperPlugin =
    (pkgs.runCommand "obs-gstreamer" { } ''
      mkdir -p $out/lib/obs-plugins
      touch $out/lib/obs-plugins/obs-gstreamer.so
    '')
    // {
      obsWrapperArguments = [
        "--set"
        "OBS_TEST_WRAPPER_ARG"
        "from-integration"
      ];
    };
in
{
  nixpkgs.overlays = [
    (_final: prev: {
      obs-studio-plugins = prev.obs-studio-plugins // {
        wlrobs = namedPlugin;
        obs-gstreamer = wrapperPlugin;
      };
    })
  ];

  programs.obs-studio = {
    enable = true;
    package = obsPackage;
    plugins = [ rawPlugin ];
    integrations = {
      wlrobs.enable = true;
      obs-gstreamer.enable = true;
      local-test-plugin = {
        enable = true;
        package = pkgs.runCommand "local-test-plugin" { } ''
          mkdir -p $out/lib/obs-plugins
          touch $out/lib/obs-plugins/local-test-plugin.so
        '';
        extraConfigFiles."config.json".text = ''
          {"enabled":true}
        '';
      };
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      activationScript = pkgs.writeScript "obs-studio-activation" config.home.activation.obsStudioConfig.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      sed "s|@TMPDIR@|$TMPDIR|g" ${activationScript} > $TMPDIR/activate
      run() { "$@"; }
      . $TMPDIR/activate

      assertFileExists home-path/lib/obs-plugins/raw-plugin.so
      assertFileExists home-path/lib/obs-plugins/wlrobs.so
      assertFileExists home-path/lib/obs-plugins/obs-gstreamer.so
      assertFileExists home-path/lib/obs-plugins/local-test-plugin.so
      assertFileContains home-path/bin/obs "OBS_TEST_WRAPPER_ARG"
      assertFileContains "$HOME/.config/obs-studio/plugin_config/local-test-plugin/config.json" '"enabled":true'
      ${pkgs.jq}/bin/jq -e '.files[] | select(.path == "plugin_config/local-test-plugin/config.json" and .kind == "raw" and .origin == "integrations.local-test-plugin.extraConfigFiles.config.json")' "$HOME/.local/state/home-manager/obs-studio/manifest.json" >/dev/null
    '';
}
