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
      # Test the plugin directories loop structure
      assertFileContains home-files/.zshrc '# Add plugin directories to PATH and fpath'
      assertFileContains home-files/.zshrc 'plugin_dirs=('
      assertFileContains home-files/.zshrc 'mockPlugin'
      assertFileContains home-files/.zshrc 'for plugin_dir in "''${plugin_dirs[@]}"; do'
      assertFileContains home-files/.zshrc 'path+="/home/hm-user/.zsh/plugins/$plugin_dir"'
      assertFileContains home-files/.zshrc 'fpath+="/home/hm-user/.zsh/plugins/$plugin_dir"'

      # Test the completion paths loop structure
      assertFileContains home-files/.zshrc '# Add completion paths to fpath'
      assertFileContains home-files/.zshrc 'completion_paths=('
      assertFileContains home-files/.zshrc 'mockPlugin/share/zsh/site-functions'
      assertFileContains home-files/.zshrc 'mockPlugin/share/zsh/vendor-completions'
      assertFileContains home-files/.zshrc 'for completion_path in "''${completion_paths[@]}"; do'
      assertFileContains home-files/.zshrc 'fpath+="/home/hm-user/.zsh/plugins/$completion_path"'

      # Test the plugin loading structure
      assertFileContains home-files/.zshrc '# Source plugins'
      assertFileContains home-files/.zshrc 'plugins=('
      assertFileContains home-files/.zshrc 'mockPlugin/share/mockPlugin/mockPlugin.plugin.zsh'
      assertFileContains home-files/.zshrc 'for plugin in "''${plugins[@]}"; do'
      assertFileContains home-files/.zshrc '[[ -f "/home/hm-user/.zsh/plugins/$plugin" ]] && source "/home/hm-user/.zsh/plugins/$plugin"'
      assertFileContains home-files/.zshrc 'done'
    '';
  };
}
