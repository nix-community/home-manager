{
  config = {
    programs.sheldon = {
      enable = true;
      settings = {
        shell = "zsh";
        plugins = {
          zsh-syntax-highlighting = {
            github = "zsh-users/zsh-syntax-highlighting";
            apply = [ "defer" ];
          };
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

  nmt.script = "assertFileContent home-files/.config/sheldon/plugins.toml ${./plugins.toml}";
}
