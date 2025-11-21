{
  config,
  ...
}:
{
  programs.docker-cli = {
    enable = true;

    configDir = ".docker2";

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
      configTestPath = "home-files/${cfgDocker.configDir}/config.json";
      configHomePath = "/home/hm-user/${cfgDocker.configDir}";
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
