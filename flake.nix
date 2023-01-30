{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
      packages = std.harvest self [ "godot" "packages" ];
    };
}

