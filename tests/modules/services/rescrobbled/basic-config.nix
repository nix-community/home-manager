{ pkgs, ... }:
{
  services.rescrobbled = {
    enable = true;
    settings = {
      lastfm-key = "Last.fm API key";
      lastfm-secret = "Last.fm API secret";
      min-play-time = 0;
      player-whitelist = [ "Player MPRIS identity or bus name" ];
      filter-script = "path/to/script";
      use-track-start-timestamp = false;

      listenbrainz = [
        {
          url = "Custom API URL";
          token = "User token";
        }
      ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/rescrobbled/config.toml
    assertFileContent home-files/.config/rescrobbled/config.toml \
      ${pkgs.writeText "settings-expected" ''
        filter-script = "path/to/script"
        lastfm-key = "Last.fm API key"
        lastfm-secret = "Last.fm API secret"
        min-play-time = 0
        player-whitelist = ["Player MPRIS identity or bus name"]
        use-track-start-timestamp = false

        [[listenbrainz]]
        token = "User token"
        url = "Custom API URL"
      ''}

    service=home-files/.config/systemd/user/rescrobbled.service

    assertFileExists $service
    assertFileRegex $service 'Description=An MPRIS scrobbler'
    assertFileRegex $service 'Wants=network-online.target'
    assertFileRegex $service 'After=network-online.target'
    assertFileRegex $service 'WantedBy=default.target'
  '';
}
