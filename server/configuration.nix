{ modulesPath, lib, pkgs, ... } @ args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  virtualisation.docker.enable = true;

  users.users.ditio = {
    isNormalUser = true;
    description = "Ditio deploy user";
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsK4/2jVXMMRkh8tGOK6Xsc6hYnOaNiaegTlhkkCL8K cepheus@desktop"
    ];
    home = "/home/ditio";
  };

  systemd.tmpfiles.rules = [
    "d /srv/ditio 0755 ditio ditio -"
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAiepvcsXy862tnbxCsB323g0AQzUrJubv/Jk3uwqrF cepheus@desktop"
  ];

  services.openssh.passwordAuthentication = false;

  system.stateVersion = "24.05";
}