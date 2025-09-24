# Shared users; hosts can add more groups with mkAfter/mkMerge
{ config, lib, pkgs, ... }:
let
  defaultShell = pkgs.bashInteractive;
in
{
  users.users.hummingbot = {
    isNormalUser = true;
    description = "Steven Buglione";
    shell = defaultShell;
    # Keep minimal here; host files can append:
    extraGroups = lib.mkDefault [ "wheel" ];
  };
}
