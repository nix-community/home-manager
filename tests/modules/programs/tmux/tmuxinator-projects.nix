{
  config = {
    programs.tmux = {
      enable = true;
      tmuxinator = {
        enable = true;
        projects = {
          myproject = {
            name = "myproject";
            root = "~/code/myproject";
            windows = [
              {
                editor = {
                  layout = "main-vertical";
                  panes = [
                    { editor = [ "vim" ]; }
                    "guard"
                  ];
                };
              }
              { server = "bundle exec rails s"; }
              { logs = "tail -f log/development.log"; }
            ];
          };
          my-second-project = {
            name = "my-second-project";
            root = "~/code/my-second-project";
          };
        };
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/tmuxinator/myproject.yaml
      assertFileContent home-files/.config/tmuxinator/myproject.yaml ${./tmuxinator-projects-1.yaml}
      assertFileExists home-files/.config/tmuxinator/my-second-project.yaml
      assertFileContent home-files/.config/tmuxinator/my-second-project.yaml ${./tmuxinator-projects-2.yaml}
    '';
  };
}
