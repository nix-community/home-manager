{ ... }:
{
  config = {
    programs.fish = {
      enable = true;

      functions = {
        normal-function = "";
        event-handler = {
          body = "";
          onEvent = "test";
        };
        variable-handler = {
          body = "";
          onVariable = "test";
        };
        job-handler = {
          body = "";
          onJobExit = "10";
        };
        signal-handler = {
          body = "";
          onSignal = "10";
        };
        process-handler = {
          body = "";
          onProcessExit = "10";
        };
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/fish/config.fish
      assertFileContains home-files/.config/fish/config.fish "source /home/hm-user/.config/fish/functions/event-handler.fish"
      assertFileContains home-files/.config/fish/config.fish "source /home/hm-user/.config/fish/functions/variable-handler.fish"
      assertFileContains home-files/.config/fish/config.fish "source /home/hm-user/.config/fish/functions/job-handler.fish"
      assertFileContains home-files/.config/fish/config.fish "source /home/hm-user/.config/fish/functions/signal-handler.fish"
      assertFileContains home-files/.config/fish/config.fish "source /home/hm-user/.config/fish/functions/process-handler.fish"
      assertFileNotRegex home-files/.config/fish/config.fish "source /home/hm-user/.config/fish/functions/normal-function.fish"
    '';
  };
}
