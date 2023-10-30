nixpkgs: pkgs: flake:

let
  machines = builtins.attrNames flake.nixosConfigurations;
  validMachines = nixpkgs.lib.remove ""
    (nixpkgs.lib.forEach machines
      (x: nixpkgs.lib.optionalString
        (flake.nixosConfigurations."${x}".config.deploy.enable) "${x}"));
  mkDeployScript = import ./make-deploy-script.nix { inherit nixpkgs pkgs flake; };
  #All main arguments to nixos-rebuild (taken from manpage), except 'edit.
  rebuildActions = [ "switch" "boot" "test" "build" "dry-build" "dry-activate" "build-vm" "build-vm-with-bootloader" ];
in
nixpkgs.lib.genAttrs
  (nixpkgs.lib.flatMap (machine: map (action: "${machine}-${action}") rebuildActions) validMachines)
  (x:
  let
    parts = builtins.split "-" x;
    machine = builtins.head parts;
    action = builtins.last parts;
  in
  {
    type = "app";
    program = toString (mkDeployScript {
      machine = machine;
      dryRun = action;
    });
  }
  )
