{
  home.stateVersion = "21.11";
  programs.pet = {
    enable = true;
    settings = {
      General = {
        backend = "Gitlab";
        editor = "nvim";
      };
      Gitlab = {
        access_token = "1234";
        file_name = "pet-snippets.toml";
        visibility = "public";
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/pet/config.toml \
      ${
        builtins.toFile "pet-settings.toml" ''
          [General]
          backend = "Gitlab"
          editor = "nvim"
          selectcmd = "fzf"
          snippetfile = "/home/hm-user/.config/pet/snippet.toml"

          [Gitlab]
          access_token = "1234"
          file_name = "pet-snippets.toml"
          visibility = "public"
        ''
      }
  '';
}
