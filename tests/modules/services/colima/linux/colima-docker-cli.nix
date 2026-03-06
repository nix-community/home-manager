{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.docker-cli = {
    enable = true;
    configDir = "${config.xdg.configHome}/docker";
  };

  services.colima = {
    enable = true;
    colimaHomeDir = "${config.xdg.configHome}/colima";
    limaHomeDir = "${config.xdg.dataHome}/lima";
    package = config.lib.test.mkStubPackage {
      name = "colima";
      outPath = "@colima@";
    };
    dockerPackage = config.lib.test.mkStubPackage {
      name = "docker";
      outPath = "@docker@";
    };
    perlPackage = config.lib.test.mkStubPackage {
      name = "perl";
      outPath = "@perl@";
    };
    sshPackage = config.lib.test.mkStubPackage {
      name = "openssh";
      outPath = "@openssh@";
    };
    coreutilsPackage = config.lib.test.mkStubPackage {
      name = "coreutils";
      outPath = "@coreutils@";
    };
    curlPackage = config.lib.test.mkStubPackage {
      name = "curl";
      outPath = "@curl@";
    };
    bashPackage = config.lib.test.mkStubPackage {
      name = "bashNonInteractive";
      outPath = "@bashNonInteractive@";
    };
  };

  nmt.script =
    let
      cfgColima = config.services.colima;
      cfgDocker = config.programs.docker-cli;
      pathColimaHome = "/home/hm-user/${cfgColima.colimaHomeDir}";
      pathDockerConfig = "home-files/${cfgDocker.configDir}/config.json";
    in
    ''
      assertPathNotExists home-files/.config/colima/default/colima.yaml

      serviceFile=home-files/.config/systemd/user/colima-default.service
      assertFileExists "$serviceFile"
      assertFileContent "$serviceFile" ${./colima-docker-cli-expected.service}

      assertFileExists "${pathDockerConfig}"
      assertFileContent "${pathDockerConfig}" ${./colima-docker-cli-expected.json}

      assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
        'export COLIMA_HOME="${pathColimaHome}"'
    '';
}
