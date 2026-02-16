{
  config,
  ...
}:
{
  programs.docker-cli = {
    enable = true;

    configDir = ".docker2";

    contexts = {
      example = {
        Metadata = {
          Description = "example1";
        };
        Endpoints = {
          docker = {
            Host = "unix://example2";
          };
        };
      };
    };
  };

  nmt.script =
    let
      cfgDocker = config.programs.docker-cli;
      configTestPath = "home-files/${cfgDocker.configDir}/contexts/meta/50d858e0985ecc7f60418aaf0cc5ab587f42c2570a884095a9e8ccacd0f6545c/meta.json";
    in
    ''
      assertPathNotExists home-files/.docker/config.json
      assertFileExists ${configTestPath}
      assertFileContent ${configTestPath} \
        ${./example-contexts.json}
    '';
}
