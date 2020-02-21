{ lib, ... }:

with lib;

{
  options.lieer.sync = {
    enable = mkEnableOption "lieer synchronization service";

    frequency = mkOption {
      type = types.str;
      default = "*:0/5";
      description = ''
        How often to synchronize the account.
        </para><para>
        This value is passed to the systemd timer configuration as the
        onCalendar option. See
        <citerefentry>
          <refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum>
        </citerefentry>
        for more information about the format.
      '';
    };
  };
}
