{
  programs = {
    smug = {
      enable = true;

      projects = {

        blogdemo = {
          root = "~/Developer/blog";
          beforeStart = [
            "docker-compose -f my-microservices/docker-compose.yml up -d" # my-microservices/docker-compose.yml is a relative to `root`-al
          ];
          env = { FOO = "bar"; };
          stop = [ "docker stop $(docker ps -q)" ];
          windows = [
            {
              name = "code";
              root = "blog";
              manual = true;
              layout = "main-vertical";
              commands = [ "docker-compose start" ];
              panes = [{
                type = "horizontal";
                root = ".";
                commands = [ "docker-compose exec php /bin/sh" "clear" ];
              }];
            }

            {
              name = "infrastructure";
              root = "~/Developer/blog/my-microservices";
              layout = "tiled";
              commands = [ "docker-compose start" ];
              panes = [{
                type = "horizontal";
                root = ".";
                commands = [
                  "docker-compose up -d"
                  "docker-compose exec php /bin/sh"
                  "clear"
                ];
              }];
            }
          ];
        };

      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/smug/blogdemo.yml ${./blogdemo.yml}
  '';
}
