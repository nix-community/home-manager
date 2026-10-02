_:

{
  lakectl-backup =
    { config, ... }:
    {
      config = {
        home.stateVersion = "24.11";

        services.lakectl-backup = {
          enable = true;
          package = config.lib.test.mkStubPackage {
            name = "lakectl";
            buildScript = "mkdir -p $out/bin; touch $out/bin/lakectl; chmod +x $out/bin/lakectl";
          };
          backups.my-test = {
            paths = [ "/tmp/testpath" ];
            repository = "test-repo";
            branch = "main";
            calendar = "hourly";
            commitMessage = "Test commit";
          };
        };

        nmt.script = ''
          wrapperFile=$(normalizeStorePaths home-path/bin/lakectl-backup-my-test)
          assertFileExists "$wrapperFile"

          assertFileRegex "$wrapperFile" "echo \"Starting lakectl backup for my-test...\""
          assertFileRegex "$wrapperFile" "echo \"Uploading /tmp/testpath...\""
          assertFileRegex "$wrapperFile" "fs.*upload.*--recursive.*/tmp/testpath.*lakefs://test-repo/main/"
          assertFileRegex "$wrapperFile" "commit.*lakefs://test-repo/main.*-m.*Test commit"
          if [[ -d "$TESTED/LaunchAgents" ]]; then
            assertFileExists "$TESTED/LaunchAgents/org.nix-community.home.lakectl-backup-my-test.plist"
          else
            assertFileExists "$TESTED/home-files/.config/systemd/user/lakectl-backup-my-test.service"
            assertFileExists "$TESTED/home-files/.config/systemd/user/timers.target.wants/lakectl-backup-my-test.timer"
          fi
        '';
      };
    };
}
