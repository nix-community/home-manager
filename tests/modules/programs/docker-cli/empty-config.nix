{
  config,
  ...
}:
let
  cfgDocker = config.programs.docker-cli;
in
{
  programs.docker-cli = {
    configDir = ".docker2";
  };

  nmt.script = ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'DOCKER_CONFIG'
    assertPathNotExists home-files/${cfgDocker.configDir}
  '';
}
