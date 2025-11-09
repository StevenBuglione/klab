# Shared “boring but important” defaults
{ config, lib, pkgs, ... }:
{
  # Nix & nixpkgs
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;


  # Locale & time
  time.timeZone = lib.mkDefault "America/New_York";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Shell niceties
  programs.bash.completion.enable = true;

  # Base packages common to both hosts (hosts can extend with ++)
  environment.systemPackages = with pkgs; [
    bashInteractive
    curl wget rsync
    iproute2 iputils
    vim htop git openssh 
    ethtool usbutils pciutils
  ];

  environment.etc."gai.conf".text = ''
    precedence ::ffff:0:0/96  100
  '';
  
  # Docker Configuration
  olab.hummingbot.docker = {
    enable = true;
    mode = "rootful";
  };

  ## Docker Swarm Ports
  networking.firewall.allowedTCPPorts = [ 2377 7946 ];
  networking.firewall.allowedUDPPorts = [ 7946 4789 ];


  boot.loader.timeout = 5;

  # Sudo: no password for wheel (override per-host if you like)
  security.sudo.wheelNeedsPassword = lib.mkDefault false;
}
