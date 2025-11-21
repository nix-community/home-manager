{ pkgs, ... }:
{
  config = {
    programs.clock-rs.enable = true;

    tests.stubs.clock-rs = { };

    nmt.script =
      let
        configDir =
          if pkgs.stdenv.isDarwin then
            "home-files/Library/Application Support/clock-rs"
          else
            "home-files/.config/clock-rs";
      in
      ''
        assertPathNotExists "${configDir}/conf.toml"
      '';
  };
}
