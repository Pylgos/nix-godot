{ inputs, cell }:

let
  inherit (inputs) nixpkgs;
in
{
  buildGodotCpp = godot-headers:
    let in
    nixpkgs.mkDerivation {
      pname = "godot-cpp";
      version = "idk";
      src = inputs.godot-cpp-source;
      nativeBuildInputs = [ nixpkgs.cmake ];
    };
}
