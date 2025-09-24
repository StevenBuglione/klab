# Server-side SSH defaults + optional client defaults
{ lib, ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;         # flip to false when keys are rolled out
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      # You can add more hardening here (MACs, KexAlgorithms, etc.) if needed.
    };
  };

  # Optional: baseline SSH client config for all users
  programs.ssh = {
    startAgent = lib.mkDefault true;
    # KnownHosts etc. can be managed here if you want
  };
}
