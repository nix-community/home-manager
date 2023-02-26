{ config, ... }:

{
  services.cachix-agent = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@cachix-agent@"; };
    name = "test-agent";
  };

  test.stubs.nix = { };

  nmt.script = ''
    assertFileContent \
      home-files/.config/systemd/user/cachix-agent.service \
      ${
        builtins.toFile "cachix-agent.service" ''
          [Install]
          WantedBy=default.target

          [Service]
          Environment=PATH=@nix@/bin
          EnvironmentFile=/home/hm-user/.config/cachix-agent.token
          ExecStart='@cachix-agent@/bin/cachix' 'deploy' 'agent' 'test-agent' 'home-manager'
          KillMode=process
          Restart=on-failure

          [Unit]
          Description=Cachix Deploy Agent
        ''
      }
  '';
}
