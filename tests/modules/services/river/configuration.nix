{
  wayland.windowManager.river = {
    enable = true;
    extraSessionVariables = {
      FOO = "foo";
      BAR = "bar";
    };
    extraConfig = ''
      exec my-window-manager
    '';
  };

  nmt.script = ''
    riverInit=home-files/.config/river/init
    assertFileExists "$riverInit"
    assertFileIsExecutable "$riverInit"

    normalizedConfig=$(normalizeStorePaths "$riverInit")
    assertFileContent "$normalizedConfig" "${./init}"

    assertFileExists home-files/.config/systemd/user/river-session.target
  '';
}
