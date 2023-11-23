{ inputs, ... }: {
  perSystem = { config, self', inputs', pkgs, lib, ... }: {

    /*
      Check the links, including anchors (not currently supported by mdbook)

      Separate check so that output can always be inspected with browser.
    */
    checks.linkcheck = pkgs.runCommand "linkcheck"
      {
        nativeBuildInputs = [ pkgs.lychee ];
        site = config.packages.default;
        config = ../lychee-offline.toml;
      } ''
      echo Checking $site
      lychee --offline --config $config $site -vvv

      touch $out
    '';

    packages = {
      default = pkgs.stdenvNoCC.mkDerivation {
        name = "site";
        nativeBuildInputs = [ pkgs.mdbook pkgs.mdbook-linkcheck ];
        src = ./.;
        buildPhase = ''
          runHook preBuild

          {
            while read ln; do
              case "$ln" in
                *end_of_intro*)
                  break
                  ;;
                *)
                  echo "$ln"
                  ;;
              esac
            done
            cat src/intro-continued.md
          } <${inputs.flake-parts + "/README.md"} >src/README.md

          mkdir -p src/options
          for f in ${config.packages.generated-docs}/*.html; do
            cp "$f" "src/options/$(basename "$f" .html).md"
          done
          mdbook build --dest-dir $TMPDIR/out
          cp -r $TMPDIR/out/html $out
          cp _redirects $out

          echo '<html><head><script>window.location.pathname = window.location.pathname.replace(/options.html$/, "") + "options/flake-parts.html"</script></head><body><a href="options/flake-parts.html">to the options</a></body></html>' \
            >$out/options.html

          runHook postBuild
        '';
        dontInstall = true;
      };
    };
  };
}
