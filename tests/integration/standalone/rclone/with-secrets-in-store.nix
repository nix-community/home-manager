{ pkgs, ... }: {
  programs.rclone.remotes = {
    alices-cool-remote-v2 = {
      config = {
        type = "b2";
        hard_delete = true;
      };
      secrets = {
        account = "${pkgs.writeText "acc" ''
          super-secret-account-id
        ''}";
        key = "${pkgs.writeText "key" ''
          api-key-from-file
        ''}";
      };
    };
  };
}
