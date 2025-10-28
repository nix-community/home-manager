{ config, pkgs, ... }:
{
  programs.zsh.enable = true;
  programs.nushell.enable = true;

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

  nmt.script =
    let
      nushellConfigDir =
        if pkgs.stdenv.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell"
        else
          "home-files/.config/nushell";
    in
    ''
      assertFileContent \
        home-files/.dir_colors \
        ${./settings-expected.conf}


      assertFileRegex \
        home-files/.zshrc \
        "eval \$(${pkgs.coreutils}/bin/dircolors -b ~/.dir_colors)"

      assertFileExists "${nushellConfigDir}/env.nu"
      assertFileRegex  "${nushellConfigDir}/env.nu" \
        "source /nix/store/[^/]*-dircolors.nu"
    '';
}
