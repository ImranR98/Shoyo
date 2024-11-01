{

#### NOTE: This flake is provided only as a convenience for Nix users.
# The SDK versions may drift out of sync with the project dependencies.
# If you are a Nix user and find that the versions don't match,
# please update the flake and make a PR.

description = "Flutter 3.24.x";
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Flutter 3.24 is 'flutter' on the unstable channel as of 24.05
  flake-utils.url = "github:numtide/flake-utils";
};
outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };
      buildToolsVersion = "34.0.0";
      androidComposition = pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = [ buildToolsVersion "30.0.3" ];
        platformVersions = [ "34" "33" "31"];
        abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
      };
      androidSdk = androidComposition.androidsdk;
    in
    {
      devShell =
        with pkgs; mkShell rec {
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          buildInputs = [
            flutter
            androidSdk # The customized SDK that we've made above
            jdk17
            aapt
          ];
        };
    });
}
