{ cell, inputs }:

let
  nixpkgs = inputs.nixpkgs;
  l = nixpkgs.lib // builtins;
  inherit (cell.lib) buildGodot4;
in
{
  godot-master = buildGodot4 { src = inputs.godot-master-source; };
}