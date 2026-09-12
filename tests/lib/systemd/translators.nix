{ lib, pkgs, ... }:

let
  unitResult = lib.hm.systemd.toHmIni {
    description = "Test service";
    bindsTo = [ "other.service" ];
    partOf = [ "target.service" ];
    onFailure = [ "failed.service" ];
    onSuccess = [ "success.service" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      FOO = "bar";
    };
  };

  socketResult = lib.hm.systemd.toHmIniSocket {
    description = "Test socket";
    listenStreams = [ "/run/test.sock" ];
    wantedBy = [ "sockets.target" ];
  };

  expectedUnit = pkgs.writeText "systemd-unit.expected" (
    builtins.toJSON {
      Unit = {
        Description = "Test service";
        BindsTo = [ "other.service" ];
        PartOf = [ "target.service" ];
        OnFailure = [ "failed.service" ];
        OnSuccess = [ "success.service" ];
      };
      Service = {
        Environment = [ "FOO=bar" ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    }
  );

  actualUnit = pkgs.writeText "systemd-unit.actual" (builtins.toJSON unitResult);

  expectedSocket = pkgs.writeText "systemd-socket.expected" (
    builtins.toJSON {
      Unit = {
        Description = "Test socket";
      };
      Socket = {
        ListenStream = [ "/run/test.sock" ];
      };
      Install = {
        WantedBy = [ "sockets.target" ];
      };
    }
  );

  actualSocket = pkgs.writeText "systemd-socket.actual" (builtins.toJSON socketResult);
in
{
  nmt.script = ''
    assertFileContent ${actualUnit} ${expectedUnit}
    assertFileContent ${actualSocket} ${expectedSocket}
  '';
}
