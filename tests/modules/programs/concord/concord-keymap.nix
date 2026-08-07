{
  programs.concord = {
    enable = true;
    keymapSettings = {
      StartComposer = {
        keys = [ "c" ];
      };
      ClosePopup = "q";
      OpenDebugLog = "`";
      ReplyMessage = "<leader>mr";
      VoiceDeafen = "<leader>vd";
      VoiceMute = "<leader>vm";
      ToggleStream = "<leader>vs";
      VoiceLeave = "<leader>vl";

      groups = {
        "<leader>v" = "Voice";
      };

      guild_actions = {
        LeaveServer = {
          keys = [ "l" ];
          description = "leave server";
        };
      };

      channel_actions = {
        ToggleMute = {
          keys = [ "x" ];
          description = "mute channel";
        };
        ToggleStream = {
          keys = [ "s" ];
          description = "toggle screen share";
        };
        WatchStream = {
          keys = [ "w" ];
          description = "watch stream";
        };
        VoiceParticipantAudio = {
          keys = [ "v" ];
          description = "participant audio";
        };
      };

      message_actions = {
        OpenThread = {
          keys = [ "t" ];
          description = "open thread";
        };
        GoToReferencedMessage = "g";
      };

      notification_inbox_actions = {
        MarkRead = "r";
        MarkAllRead = "a";
      };

      composer = {
        OpenEditor = "<C-o>";
        DeletePreviousWord = "<A-backspace>";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/concord/keymap.toml
    assertFileContent home-files/.config/concord/keymap.toml \
      ${./concord-keymap.toml}
  '';
}
