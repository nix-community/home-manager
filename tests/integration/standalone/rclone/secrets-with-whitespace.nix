{ pkgs, ... }: {
  programs.rclone.remotes = {
    alices-cool-remote-v3 = {
      config = {
        type = "memory";
        description = "alices speeedy remote";
      };
      secrets.spaces-secret = "${pkgs.writeText "secret" ''
        This is a secret with spaces, it has single spaces,                  and lots of spaces :3
      ''}";
    };
  };
}
