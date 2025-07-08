{
  config,
  ...
}:
let
  cfgDocker = config.programs.docker-cli;
in
{
  programs.docker-cli = {
    configPath = ".docker/empty.json";
  };

  nmt.script = ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'DOCKER_CONFIG'
    assertPathNotExists home-files/.docker/config.json
    assertPathNotExists home-files/${cfgDocker.configPath}
  '';
}
