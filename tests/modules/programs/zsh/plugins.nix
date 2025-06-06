{ pkgs, ... }:

let
  mockZshPluginSrc = pkgs.writeText "mockZshPluginSrc" "echo example";
in
{
  config = {
    programs.zsh = {
      enable = true;
      plugins = [
        {
          name = "mockPlugin";
          file = "share/mockPlugin/mockPlugin.plugin.zsh";
          src = mockZshPluginSrc;
          completions = [
            "share/zsh/site-functions"
            "share/zsh/vendor-completions"
          ];
        }
      ];
    };

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileRegex home-files/.zshrc '^path+="$HOME/.zsh/plugins/mockPlugin"$'
      assertFileRegex home-files/.zshrc '^fpath+="$HOME/.zsh/plugins/mockPlugin"$'
      assertFileRegex home-files/.zshrc '^fpath+=("$HOME/.zsh/plugins/mockPlugin/share/zsh/site-functions" "$HOME/.zsh/plugins/mockPlugin/share/zsh/vendor-completions")$'
    '';
  };
}
