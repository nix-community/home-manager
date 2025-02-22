{
  config = {
    programs.tmux = {
      aggressiveResize = true;
      clock24 = true;
      enable = true;
      keyMode = "vi";
      newSession = true;
      reverseSplit = true;
    };

    nixpkgs.overlays = [
      (self: super: {
        tmuxPlugins = super.tmuxPlugins // {
          sensible = super.tmuxPlugins.sensible // { rtp = "@sensible_rtp@"; };
        };
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.config/tmux/tmux.conf
      assertFileContent home-files/.config/tmux/tmux.conf ${./vi-all-true.conf}
    '';
  };
}
