{ config, pkgs, ... }:

{
  programs.bash.enable = true;
  programs.zsh.enable = true;
  programs.fish.enable = true;
  programs.nushell.enable = true;

  programs.tere = {
    enable = true;
    package = null;
    enableBashIntegration = true;
    enableZshIntegration = false;
    enableFishIntegration = true;
    enableNushellIntegration = true;
  };

  nmt.script =
    let
      nushellConfig =
        if pkgs.stdenv.hostPlatform.isDarwin && !config.xdg.enable then
          "home-files/Library/Application Support/nushell/config.nu"
        else
          "home-files/.config/nushell/config.nu";
    in
    ''
      # A null package must not install tere, but the wrappers still work.
      assertPathNotExists home-path/bin/tere

      assertFileContains home-files/.bashrc 'tere() {'

      assertFileExists home-files/.zshrc
      assertFileNotRegex home-files/.zshrc 'tere\(\)'

      assertFileContent home-files/.config/fish/functions/tere.fish \
        ${./fish-integration-expected.fish}

      assertFileContains '${nushellConfig}' \
        'def --wrapped --env tere [...args] {'
      assertFileContains '${nushellConfig}' 'let result = ( ^tere ...$args )'
    '';
}
