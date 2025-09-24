{ lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.klab.laptopAsServer.enable = mkEnableOption "keep the laptop running when the lid is closed";

  config = mkIf config.klab.laptopAsServer.enable {
    # Don’t suspend/hibernate on lid close
    services.logind = {
      lidSwitch = "ignore";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
    };

    # Extra belt-and-suspenders
    systemd.sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
      SuspendState=
      HibernateState=
    '';
  };
}
