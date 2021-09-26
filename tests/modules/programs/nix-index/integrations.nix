{ lib, pkgs, ... }:

let
  fishRegex = ''
    function __fish_command_not_found_handler --on-event fish_command_not_found
        /nix/store/.*command-not-found $argv
    end
  '';
in {
  config = {
    programs.bash.enable = true;
    programs.fish.enable = true;
    programs.zsh.enable = true;

    # Needed to avoid error with dummy fish package.
    xdg.dataFile."fish/home-manager_generated_completions".source =
      lib.mkForce (builtins.toFile "empty" "");

    test.stubs = {
      zsh = { };
      fish = { };
    };

    programs.nix-index.enable = true;

    nmt.script = ''
      # Bash integration
      assertFileExists home-files/.bashrc
      assertFileRegex \
        home-files/.bashrc \
        'source /nix/store/.*nix-index.*/etc/profile.d/command-not-found.sh'

      # Zsh integration
      assertFileExists home-files/.zshrc
      assertFileRegex \
        home-files/.zshrc \
        'source /nix/store/.*nix-index.*/etc/profile.d/command-not-found.sh'

      # Fish integration
      assertFileExists home-files/.config/fish/config.fish
      assertFileRegex \
        home-files/.config/fish/config.fish '${fishRegex}'
    '';
  };
}
