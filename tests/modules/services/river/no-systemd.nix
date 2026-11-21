{
  wayland.windowManager.river = {
    enable = true;
    package = null;
    systemd.enable = false;
    extraConfig = ''
      exec my-window-manager
    '';
  };

  nmt.script = ''
    riverInit=home-files/.config/river/init
    assertFileExists "$riverInit"
    assertFileIsExecutable "$riverInit"

    normalizedConfig=$(normalizeStorePaths "$riverInit")
    assertFileContent "$normalizedConfig" "${./init-no-systemd}"

    assertPathNotExists home-files/.config/systemd/user/river-session.target
  '';
}
