{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = {
    programs.tmux = {
      aggressiveResize = true;
      clock24 = true;
      enable = true;
      keyMode = "emacs";
      newSession = true;
      reverseSplit = true;

      plugins = with pkgs.tmuxPlugins; [
        logging
      ];
    };

    nixpkgs.overlays = [
      (self: super: {
        tmuxPlugins =
          super.tmuxPlugins
          // {
            logging =
              super.tmuxPlugins.logging
              // {
                rtp = "@tmuxplugin_logging_rtp@";
              };

            sensible =
              super.tmuxPlugins.sensible
              // {
                rtp = "@tmuxplugin_sensible_rtp@";
              };
          };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/tmux/tmux.conf
      assertFileContent home-files/.config/tmux/tmux.conf ${./emacs-with-plugins.conf}
    '';
  };
}
