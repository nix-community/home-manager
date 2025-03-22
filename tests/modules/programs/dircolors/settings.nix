{ pkgs, ... }: {
  config = {
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
        home-files/.dir_colors \
        ${./settings-expected.conf}


      assertFileRegex  \
        home-files/.zshrc \
        "eval \$(${pkgs.coreutils}/bin/dircolors -b ~/.dir_colors)"
    '';
  };
}
