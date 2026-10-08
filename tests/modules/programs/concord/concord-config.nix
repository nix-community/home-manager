{
  programs.concord = {
    enable = true;
    settings = {
      display = {
        image_protocol = "auto";
        disable_image_preview = false;
        show_avatars = true;
        show_images = true;
        media_playback = false;
        image_preview_quality = "balanced";
        attachment_viewer_quality = "original";
        show_custom_emoji = true;
        circular_avatars = false;
      };

      composer.emojis_as_links = false;
      presence.share_rich_presence = true;
      credentials.store = "auto";

      notifications = {
        desktop_notifications = true;
        notification_icon = "/path/to/icon.svg";
        notification_sound = "/path/to/message.wav";
        voice_join_sound = "/path/to/join.wav";
        voice_leave_sound = "/path/to/leave.wav";
      };

      voice = {
        self_mute = false;
        self_deaf = false;
        allow_microphone_transmit = false;
        push_to_talk = false;
        push_to_talk_shortcut = "F8";
        noise_suppression = true;
        microphone_sensitivity = -30;
        microphone_volume = 100;
        voice_output_volume = 100;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/concord/config.toml
    assertFileContent home-files/.config/concord/config.toml \
      ${./concord-config.toml}
  '';
}
