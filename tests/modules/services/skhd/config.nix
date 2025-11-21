{
  services.skhd = {
    enable = true;
    config = ''
      # open terminal, blazingly fast compared to iTerm/Hyper
      cmd - return : /Applications/kitty.app/Contents/MacOS/kitty --single-instance -d ~

      # open qutebrowser
      cmd + shift - return : ~/Scripts/qtb.sh

      # open mpv
      cmd - m : open -na /Applications/mpv.app $(pbpaste)
    '';
  };

  nmt.script = ''
    configFile=home-files/.config/skhd/skhdrc
    assertFileExists $configFile
    assertFileIsExecutable "$configFile"
    assertFileContent $configFile ${./skhd-config-expected}

    serviceFile=LaunchAgents/org.nix-community.home.skhd.plist
    assertFileExists "$serviceFile"
  '';
}
