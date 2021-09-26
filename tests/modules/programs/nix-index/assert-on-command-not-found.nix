{ lib, pkgs, ... }:

{
  config = {
    programs.bash.enable = true;
    programs.fish.enable = true;
    programs.zsh.enable = true;

    programs.command-not-found.enable = true;

    # Needed to avoid error with dummy fish package.
    xdg.dataFile."fish/home-manager_generated_completions".source =
      lib.mkForce (builtins.toFile "empty" "");

    test.stubs = {
      zsh = { };
      fish = { };
    };

    programs.nix-index.enable = true;

    # 'command-not-found' does not have a 'fish' integration
    test.asserts.assertions.expected = [
      ''
        The 'programs.command-not-found.enable' option is mutually exclusive
        with the 'programs.nix-index.enableBashIntegration' option.
      ''
      ''
        The 'programs.command-not-found.enable' option is mutually exclusive
        with the 'programs.nix-index.enableZshIntegration' option.
      ''
    ];
  };
}
