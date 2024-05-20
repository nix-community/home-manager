{ config, pkgs, ... }:

let

  backups = config.programs.borgmatic.backups;

in {
  programs.borgmatic = {
    enable = true;
    backups = {
      main = {
        location = {
          sourceDirectories = [ "/my-stuff-to-backup" ];
          patterns = [ "R /" "+ my-stuff-to-backup" ];
          repositories = [ "/mnt/disk1" ];
        };
      };
    };
  };

  test.stubs.borgmatic = { };

  test.asserts.assertions.expected = [''
    Borgmatic backup configuration "main" cannot specify both 'location.sourceDirectories' and 'location.patterns'.
  ''];
}
