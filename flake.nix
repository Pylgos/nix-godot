{
  nixConfig ={
    extra-trusted-public-keys = "godot.cachix.org-1:kPibbZSZOQb/qoWUODS4M4BCdl/Ka4MHuxiEKG0E0/M=";
    extra-substituters = "https://godot.cachix.org";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/22.11";
    std.url = "github:divnix/std";
    std.inputs.nixpkgs.follows = "nixpkgs";

    godot-master-source = { url = "github:godotengine/godot"; flake = false; };
    godot-cpp-source = { url = "github:godotengine/godot-cpp"; flake = false; };
  };

  outputs = { std, self, ... } @ inputs: std.growOn
    {
      inherit inputs;
      cellsFrom = ./nix;
      cellBlocks = with std.blockTypes; [
        (installables "packages")
        (functions "lib")
      ];
    }
    {
      packages = std.harvest self [ "outputs" "packages" ];
    };
}

