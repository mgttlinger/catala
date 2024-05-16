{ ocamlPackages, fetchurl }:

ocamlPackages.overrideScope (self: super: {
  alcotest = (super.alcotest.override {}).overrideAttrs (_: {
    doCheck = false;
  });
  catala = self.callPackage ./catala.nix { };
  clerk = self.callPackage ./clerk.nix { };
  ubase = self.callPackage ./ubase.nix { };
  french_law = self.callPackage ./french_law.nix { };
})
