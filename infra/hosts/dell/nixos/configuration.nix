{ lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  klab.laptopAsServer.enable = true;
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  # Static IP on the Dell
  klab.network = {
    hostName = "dell";
    useNetworkManager = false;     # static via base networking
    dhcp = false;
    static = {
      enable = true;
      interface = "enp0s13f0u4u1";     # e.g., "eno1" or "enp3s0"
      address = "10.10.10.3";
      prefixLength = 24;
      gateway = "10.10.10.1";
      nameservers = [ "10.10.10.1" ];
    };
  };

  # klab.hummingbot.docker = {
  #   enable = true;
  #   user = "hummingbot";
  #   mode = "rootless";
  # };



  # Extend user groups specific to Dell
  users.users.hummingbot.extraGroups = [ "wheel" "networkmanager" "docker" ];

  # USB NIC / power server extras (unchanged from before)
  hardware.enableAllFirmware = true;
  boot.kernelModules = [ "usbnet" "cdc_ncm" "cdc_ether" "rndis_host" "r8152" "ax88179_178a" ];
  boot.kernelParams = [ "usbcore.autosuspend=-1" ];
  boot.extraModprobeConfig = ''options r8152 bEnableEEE=0'';

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;

  system.stateVersion = "25.05";
}
