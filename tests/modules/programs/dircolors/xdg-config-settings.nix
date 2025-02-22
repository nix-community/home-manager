{ config, pkgs, ... }: {
  config = {
    home.preferXdgDirectories = true;

    programs.zsh.enable = true;

    programs.dircolors = {
      enable = true;

      settings = {
        OTHER_WRITABLE = "30;46";
        ".sh" = "01;32";
        ".csh" = "01;32";
      };

      extraConfig = ''
        # Extra dircolors configuration.
      '';
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/dir_colors \
        ${./settings-expected.conf}

      assertFileRegex  \
        home-files/.zshrc \
        "eval \$(${pkgs.coreutils}/bin/dircolors -b ${config.xdg.configHome}/dir_colors)"
    '';
  };
}
