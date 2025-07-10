{
  config,
  ...
}:
{
  programs.docker-cli = {
    enable = true;

    configPath = ".docker/config2.json";

    settings = {
      "proxies" = {
        "default" = {
          "httpProxy" = "http://proxy.example.org:3128";
          "httpsProxy" = "http://proxy.example.org:3128";
          "noProxy" = "localhost";
        };
      };
    };
  };

  nmt.script =
    let
      cfgDocker = config.programs.docker-cli;
      configTestPath = "home-files/${cfgDocker.configPath}";
      configHomePath = "/home/hm-user/${cfgDocker.configPath}";
    in
    ''
      assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
        'export DOCKER_CONFIG="${configHomePath}"'

      assertPathNotExists home-files/.docker/config.json
      assertFileExists ${configTestPath}
      assertFileContent ${configTestPath} \
        ${./example-config.json}
    '';
}
