{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  programs.docker-cli = {
    enable = true;

    configDir = ".docker2";

    settings.proxies.default.httpProxy = "http://proxy.example.org:3128";

    registryCredentials."https://index.docker.io/v1/" = {
      username = "caniko";
      passwordFile = "/@TMPDIR@/docker-token";
    };
  };

  nmt.script =
    let
      cfgDocker = config.programs.docker-cli;
      activationScript = pkgs.writeScript "activation" config.home.activation.dockerCliRegistryCredentials.data;
      configTestPath = "$HOME/${cfgDocker.configDir}/config.json";
    in
    ''
      export HOME=$TMPDIR/hm-user
      echo -n s3cr3t > $TMPDIR/docker-token

      assertPathNotExists home-files/${cfgDocker.configDir}/config.json

      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate

      assertFileExists ${configTestPath}
      assertFileContent ${configTestPath} \
        ${./registry-credentials.json}

      $TMPDIR/activate
      assertFileContent ${configTestPath} \
        ${./registry-credentials.json}
    '';
}
