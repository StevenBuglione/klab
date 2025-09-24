{ lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./apple-silicon-support
  ];

  klab.laptopAsServer.enable = false;  # it's a desktop-style server; flip if needed

  klab.network = {
    hostName = "mac";
    useNetworkManager = false;         # simple static
    dhcp = false;
    static = {
      enable = true;
      interface = "end0";
      address = "10.10.10.5";
      prefixLength = 24;
      gateway = "10.10.10.1";
      nameservers = [ "10.10.10.1" ];
    };
  };

  klab.hummingbot.docker = {
    enable = true;
    user = "hummingbot";
    mode = "rootful";
  };

  boot.loader = {
    efi.canTouchEfiVariables = false;

    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      efiInstallAsRemovable = true;
      timeout = 5;                # GRUB’s timeout lives here
    };

    # REMOVE this line – it does not exist for GRUB:
    # configurationLimit = 20;
    # Also remove any top-level boot.loader.timeout you had.
  };
  # If available on your channel this also sets the menu timeout; harmless if ignored:
  boot.loader.timeout = 5;

  users.users.hummingbot.extraGroups = [ "wheel" "networkmanager" "docker" ];

  # Asahi firmware note:
  # hardware.asahi.peripheralFirmwareDirectory = ./firmware;  # if you vendor it for pure builds

  environment.systemPackages = with pkgs; [ ethtool usbutils pciutils ];
  
  system.autoUpgrade.flags = [ "--update-input" "nixpkgs" "--commit-lock-file" "--impure" ];
  system.stateVersion = "25.11";
}

