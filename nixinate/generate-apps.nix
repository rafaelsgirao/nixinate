nixpkgs: pkgs: flake:

let
  machines = builtins.attrNames flake.nixosConfigurations;
  validMachines = nixpkgs.lib.remove ""
    (nixpkgs.lib.forEach machines
      (x: nixpkgs.lib.optionalString
        (flake.nixosConfigurations."${x}".config.deploy.enable) "${x}"));
  mkDeployScript = import ./make-deploy-script.nix { inherit nixpkgs pkgs flake; };
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
  #   // nixpkgs.lib.genAttrs
  # (map (machineName: a + "-dry-run") validMachines)
(builtins.concatMap (machine: map (rebuildAction: "${machine}-${action}") rebuildActions) validMachines)
  (x:
  let
    parts = builtins.split "-" x;
    machineName = builtins.head parts;
    rebuildAction = builtins.last parts;
  in
  {
    type = "app";
    program = toString (mkDeployScript {
      machine = machineName;
      inherit rebuildAction;
    });
  }
  )
