{ pkgs, ... }:
{
  programs.nix-init = {
    enable = true;
    settings = {
      maintainers = [ "figsoda" ];
      nixpkgs = "<nixpkgs>";
      commit = true;
      access-tokens = {
        "github.com" = "ghp_blahblahblah...";
        "gitlab.com".command = [
          "secret-tool"
          "or"
          "whatever"
          "you"
          "use"
        ];
        "gitlab.gnome.org".file = "/path/to/api/token";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/nix-init/config.toml
    assertFileContent home-files/.config/nix-init/config.toml \
      ${pkgs.writeText "settings-expected" ''
        commit = true
        maintainers = ["figsoda"]
        nixpkgs = "<nixpkgs>"

        [access-tokens]
        "github.com" = "ghp_blahblahblah..."

        [access-tokens."gitlab.com"]
        command = ["secret-tool", "or", "whatever", "you", "use"]

        [access-tokens."gitlab.gnome.org"]
        file = "/path/to/api/token"
      ''}
  '';
}
