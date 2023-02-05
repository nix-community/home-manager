{ pkgs, ... }:

{
  config = {
    # Minimal config reproducing
    # https://github.com/nix-community/home-manager/issues/3560
    programs.ncmpcpp.enable = true;

    services.mpd.enable = true;
    services.mpd.musicDirectory = "~/music";

    test.stubs = {
      ncmpcpp = { };
      mpd = { };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/ncmpcpp/config \
        ${./ncmpcpp-issue-3560-expected-config}

      assertPathNotExists home-files/.config/ncmpcpp/bindings
    '';
  };
}
