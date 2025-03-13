{
  services.git-sync = {
    enable = true;
    repositories = {
      testWithWhitespace = {
        path = "/a path";
        uri = "git+ssh://user@example.com:/~user/path to/repo.git";
      };
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/git-sync-testWithWhitespace.service

    assertFileExists $serviceFile

    assertFileContent $serviceFile ${
      builtins.toFile "expected" ''
        [Install]
        WantedBy=default.target

        [Service]
        Environment=PATH=@openssh@/bin:@git@/bin
        Environment=GIT_SYNC_DIRECTORY='/a path'
        Environment=GIT_SYNC_COMMAND=@git-sync@/bin/git-sync
        Environment=GIT_SYNC_REPOSITORY='git+ssh://user@example.com:/~user/path to/repo.git'
        Environment=GIT_SYNC_INTERVAL=500
        ExecStart=@git-sync@/bin/git-sync-on-inotify
        Restart=on-abort

        [Unit]
        Description=Git Sync testWithWhitespace
      ''
    }
  '';
}
