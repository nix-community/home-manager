{
  config = {
    programs.sheldon = {
      enable = true;
      settings = {
        shell = "zsh";
        plugins = {
          async = {
            local = "~/.config/sheldon/async";
            use = [ "*.zsh" ];
            apply = [ "defer" ];
          };
          sync = {
            local = "~/.config/sheldon/sync";
            use = [ "*.zsh" ];
            apply = [ "source" ];
          };
          zsh-defer = {
            github = "romkatv/zsh-defer";
            apply = [ "source" ];
          };
          add-zsh-hook = { inline = "autoload -U add-zsh-hook"; };
          anyframe = { github = "mollifier/anyframe"; };
          colors = { inline = "autoload -U colors && zsh-defer colors"; };
          compinit = {
            inline = "autoload -U compinit && zsh-defer compinit -C";
          };
          fzf = { github = "junegunn/fzf"; };
          predict = { inline = "autoload -U predict-on && predict-on"; };
          starship = {
            inline = ''
              eval "$(starship init zsh)"
            '';
          };
          zcalc = { inline = "autoload -U zcalc"; };
          zsh-async = { github = "mafredri/zsh-async"; };
          zsh-complations = {
            github = "zsh-users/zsh-completions";
            apply = [ "defer" ];
          };
          zsh-history-substring-search = {
            github = "zsh-users/zsh-history-substring-search";
            apply = [ "defer" ];
          };
          zsh-syntax-highlighting = {
            github = "zsh-users/zsh-syntax-highlighting";
            apply = [ "defer" ];
          };
          zsh-terminfo = { inline = "zmodload zsh/terminfo"; };
        };
        templates = {
          defer = ''
            {{ hooks | get: "pre" | nl }}{% for file in files %}zsh-defer source "{{ file }}"
            {% endfor %}{{ hooks | get: "post" | nl }}'';
        };
      };
    };
  };

  test.stubs.sheldon = { };

  nmt.script = "assertFileContent home-files/.config/sheldon/plugins.toml ${
      ./plugins.toml
    }";
}
