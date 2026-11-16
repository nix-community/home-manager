{
  config = {
    home.shellAliases = {
      g = "git";
      ll = "ls -l";
    };

    programs.fish = {
      enable = true;
      preferAbbrs = true;
    };

    nmt = {
      description = "if fish.preferAbbrs is enabled, home.shellAliases become abbreviations";
      script = ''
        assertFileContains home-files/.config/fish/config.fish \
          "abbr --add -- g git"
        assertFileContains home-files/.config/fish/config.fish \
          "abbr --add -- ll 'ls -l'"
        assertFileNotRegex home-files/.config/fish/config.fish '^alias (g|ll) '
      '';
    };
  };
}
