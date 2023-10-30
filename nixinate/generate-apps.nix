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
# nixpkgs.lib.genAttrs
#   validMachines
#   (x:
#     {
#       type = "app";
#       program = toString (mkDeployScript {
#         machine = x;
#         dryRun = false;
#       });
#     }
#   )
  # // nixpkgs.lib.genAttrs
  # (map (a: a + "-dry-run") validMachines)
   nixpkgs.lib.genAttrs
   (map (rebuildAction: (map: machineName: (machineName + "-" + rebuildAction) validMachines) ) rebuildActions )
  # (map (a: a + "-dry-run") validMachines)
  (x:
    {
      type = "app";
      program = toString (mkDeployScript {
        machine = nixpkgs.lib.removeSuffix "-dry-run" x;
        dryRun = true;
      });
    }
  )
