{ lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./apple-silicon-support
  ];

  klab.laptopAsServer.enable = false;  # it's a desktop-style server; flip if needed

  boot.loader = {
    efi.canTouchEfiVariables = false;

    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      efiInstallAsRemovable = true;
      timeout = 5;                
    };
  };

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

  # Enable rootless Docker
  virtualisation.docker.rootless = {
    enable = true;
    # export DOCKER_HOST to your session so `docker` talks to the user socket
    setSocketVariable = true;
  };

  # Make sure the system (rootful) Docker is fully OFF to avoid conflicts
  virtualisation.docker.enable = lib.mkForce false;
  systemd.services.docker.enable = lib.mkForce false;
  systemd.sockets.docker.enable  = lib.mkForce false;

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

  users.users.hummingbot.extraGroups = [ "wheel" ];

  environment.systemPackages = with pkgs; [ ethtool usbutils pciutils docker ];
  
  system.autoUpgrade.flags = [ "--update-input" "nixpkgs" "--commit-lock-file" "--impure" ];
  system.stateVersion = "25.11";
}

