{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.klab.laptopAsServer.enable =
    mkEnableOption "keep the laptop running when the lid is closed";

  config = mkIf config.klab.laptopAsServer.enable {
    services.logind = {
      lidSwitch = "ignore";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
    };
    systemd.sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
      SuspendState=
      HibernateState=
    '';
  };
}

