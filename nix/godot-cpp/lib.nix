{ inputs, cell }:

let
  inherit (inputs) nixpkgs;
in
{
  buildGodotCpp = godot-headers:
    let in
    nixpkgs.stdenv.mkDerivation {
      pname = "godot-cpp";
      version = "idk";
      src = inputs.godot-cpp-source;
      nativeBuildInputs = with nixpkgs; [
        cmake
        python3
      ];
    };
}
