{ pkgs, ... }:

{
  config = {
    programs.fzf.tmux.enableShellIntegration = true;

    programs.sesh = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-polybar" "";
      settings = {
        default_session.startup_command = "nvim -c ':Telescope find_files'";
        session = [
          {
            name = "Downloads 📥";
            path = "~/Downloads";
            startup_command = "ls";
          }
          {
            name = "tmux config";
            path = "~/c/dotfiles/.config/tmux";
            startup_command = "nvim tmux.conf";
          }
        ];
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/sesh/sesh.toml
      assertFileContent home-files/.config/sesh/sesh.toml \
          ${./basic-configuration.toml}
    '';
  };
}
