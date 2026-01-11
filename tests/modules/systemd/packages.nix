{ pkgs, config, ... }:
let
  package = config.lib.test.mkStubPackage {
    buildScript = ''
      mkdir -p $out/share/systemd/user
      > $out/share/systemd/user/dummy.service cat <<EOF
      [Service]
      ExecStart=$out/bin/nonexistent
      EOF
    '';
  };
in
{
  systemd.user.packages = [ package ];
  nmt.script = ''
    serviceFile=home-files/.local/share/systemd/user/dummy.service
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFile" ${package}/share/systemd/user/dummy.service
  '';
}
