{
  services.cachix-agent = {
    enable = true;
    name = "test-agent";
  };

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
          ExecStart=@cachix@/bin/cachix deploy agent test-agent home-manager
          KillMode=process
          Restart=on-failure

          [Unit]
          Description=Cachix Deploy Agent
        ''
      }
  '';
}
