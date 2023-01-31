{ inputs, cell }:
let
  inherit (inputs) cells;
in
{
  inherit (cells.godot.packages) godot-master;
  inherit (cells.godot-cpp.packages) demo-extension;
}