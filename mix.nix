{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    castore = buildMix rec {
      name = "castore";
      version = "1.0.9";

      src = fetchHex {
        pkg = "castore";
        version = "${version}";
        sha256 = "5ea956504f1ba6f2b4eb707061d8e17870de2bee95fb59d512872c2ef06925e7";
      };

      beamDeps = [];
    };

    cc_precompiler = buildMix rec {
      name = "cc_precompiler";
      version = "0.1.10";

      src = fetchHex {
        pkg = "cc_precompiler";
        version = "${version}";
        sha256 = "f6e046254e53cd6b41c6bacd70ae728011aa82b2742a80d6e2214855c6e06b22";
      };

      beamDeps = [ elixir_make ];
    };

    certifi = buildRebar3 rec {
      name = "certifi";
      version = "2.12.0";

      src = fetchHex {
        pkg = "certifi";
        version = "${version}";
        sha256 = "ee68d85df22e554040cdb4be100f33873ac6051387baf6a8f6ce82272340ff1c";
      };

      beamDeps = [];
    };

    cowboy = buildErlangMk rec {
      name = "cowboy";
      version = "2.12.0";

      src = fetchHex {
        pkg = "cowboy";
        version = "${version}";
        sha256 = "8a7abe6d183372ceb21caa2709bec928ab2b72e18a3911aa1771639bef82651e";
      };

      beamDeps = [ cowlib ranch ];
    };

    cowboy_telemetry = buildRebar3 rec {
      name = "cowboy_telemetry";
      version = "0.4.0";

      src = fetchHex {
        pkg = "cowboy_telemetry";
        version = "${version}";
        sha256 = "7d98bac1ee4565d31b62d59f8823dfd8356a169e7fcbb83831b8a5397404c9de";
      };

      beamDeps = [ cowboy telemetry ];
    };

    cowlib = buildRebar3 rec {
      name = "cowlib";
      version = "2.13.0";

      src = fetchHex {
        pkg = "cowlib";
        version = "${version}";
        sha256 = "e1e1284dc3fc030a64b1ad0d8382ae7e99da46c3246b815318a4b848873800a4";
      };

      beamDeps = [];
    };

    db_connection = buildMix rec {
      name = "db_connection";
      version = "2.7.0";

      src = fetchHex {
        pkg = "db_connection";
        version = "${version}";
        sha256 = "dcf08f31b2701f857dfc787fbad78223d61a32204f217f15e881dd93e4bdd3ff";
      };

      beamDeps = [ telemetry ];
    };

    decimal = buildMix rec {
      name = "decimal";
      version = "1.9.0";

      src = fetchHex {
        pkg = "decimal";
        version = "${version}";
        sha256 = "b1f2343568eed6928f3e751cf2dffde95bfaa19dd95d09e8a9ea92ccfd6f7d85";
      };

      beamDeps = [];
    };

    elixir_make = buildMix rec {
      name = "elixir_make";
      version = "0.8.4";

      src = fetchHex {
        pkg = "elixir_make";
        version = "${version}";
        sha256 = "6e7f1d619b5f61dfabd0a20aa268e575572b542ac31723293a4c1a567d5ef040";
      };

      beamDeps = [ castore certifi ];
    };

    exqlite = buildMix rec {
      name = "exqlite";
      version = "0.27.0";

      src = fetchHex {
        pkg = "exqlite";
        version = "${version}";
        sha256 = "b947b9db15bb7aad11da6cd18a0d8b78f7fcce89508a27a5b9be18350fe12c59";
      };

      beamDeps = [ cc_precompiler db_connection elixir_make ];
    };

    floki = buildMix rec {
      name = "floki";
      version = "0.36.3";

      src = fetchHex {
        pkg = "floki";
        version = "${version}";
        sha256 = "fe0158bff509e407735f6d40b3ee0d7deb47f3f3ee7c6c182ad28599f9f6b27a";
      };

      beamDeps = [];
    };

    hackney = buildRebar3 rec {
      name = "hackney";
      version = "1.20.1";

      src = fetchHex {
        pkg = "hackney";
        version = "${version}";
        sha256 = "fe9094e5f1a2a2c0a7d10918fee36bfec0ec2a979994cff8cfe8058cd9af38e3";
      };

      beamDeps = [ certifi idna metrics mimerl parse_trans ssl_verify_fun unicode_util_compat ];
    };

    httpoison = buildMix rec {
      name = "httpoison";
      version = "2.2.1";

      src = fetchHex {
        pkg = "httpoison";
        version = "${version}";
        sha256 = "51364e6d2f429d80e14fe4b5f8e39719cacd03eb3f9a9286e61e216feac2d2df";
      };

      beamDeps = [ hackney ];
    };

    idna = buildRebar3 rec {
      name = "idna";
      version = "6.1.1";

      src = fetchHex {
        pkg = "idna";
        version = "${version}";
        sha256 = "92376eb7894412ed19ac475e4a86f7b413c1b9fbb5bd16dccd57934157944cea";
      };

      beamDeps = [ unicode_util_compat ];
    };

    metrics = buildRebar3 rec {
      name = "metrics";
      version = "1.0.1";

      src = fetchHex {
        pkg = "metrics";
        version = "${version}";
        sha256 = "69b09adddc4f74a40716ae54d140f93beb0fb8978d8636eaded0c31b6f099f16";
      };

      beamDeps = [];
    };

    mime = buildMix rec {
      name = "mime";
      version = "2.0.6";

      src = fetchHex {
        pkg = "mime";
        version = "${version}";
        sha256 = "c9945363a6b26d747389aac3643f8e0e09d30499a138ad64fe8fd1d13d9b153e";
      };

      beamDeps = [];
    };

    mimerl = buildRebar3 rec {
      name = "mimerl";
      version = "1.3.0";

      src = fetchHex {
        pkg = "mimerl";
        version = "${version}";
        sha256 = "a1e15a50d1887217de95f0b9b0793e32853f7c258a5cd227650889b38839fe9d";
      };

      beamDeps = [];
    };

    parse_trans = buildRebar3 rec {
      name = "parse_trans";
      version = "3.4.1";

      src = fetchHex {
        pkg = "parse_trans";
        version = "${version}";
        sha256 = "620a406ce75dada827b82e453c19cf06776be266f5a67cff34e1ef2cbb60e49a";
      };

      beamDeps = [];
    };

    phoenix = buildMix rec {
      name = "phoenix";
      version = "1.7.14";

      src = fetchHex {
        pkg = "phoenix";
        version = "${version}";
        sha256 = "c7859bc56cc5dfef19ecfc240775dae358cbaa530231118a9e014df392ace61a";
      };

      beamDeps = [ castore phoenix_pubsub phoenix_template phoenix_view plug plug_cowboy plug_crypto telemetry websock_adapter ];
    };

    phoenix_html = buildMix rec {
      name = "phoenix_html";
      version = "3.3.4";

      src = fetchHex {
        pkg = "phoenix_html";
        version = "${version}";
        sha256 = "0249d3abec3714aff3415e7ee3d9786cb325be3151e6c4b3021502c585bf53fb";
      };

      beamDeps = [ plug ];
    };

    phoenix_pubsub = buildMix rec {
      name = "phoenix_pubsub";
      version = "2.1.3";

      src = fetchHex {
        pkg = "phoenix_pubsub";
        version = "${version}";
        sha256 = "bba06bc1dcfd8cb086759f0edc94a8ba2bc8896d5331a1e2c2902bf8e36ee502";
      };

      beamDeps = [];
    };

    phoenix_template = buildMix rec {
      name = "phoenix_template";
      version = "1.0.4";

      src = fetchHex {
        pkg = "phoenix_template";
        version = "${version}";
        sha256 = "2c0c81f0e5c6753faf5cca2f229c9709919aba34fab866d3bc05060c9c444206";
      };

      beamDeps = [ phoenix_html ];
    };

    phoenix_view = buildMix rec {
      name = "phoenix_view";
      version = "2.0.4";

      src = fetchHex {
        pkg = "phoenix_view";
        version = "${version}";
        sha256 = "4e992022ce14f31fe57335db27a28154afcc94e9983266835bb3040243eb620b";
      };

      beamDeps = [ phoenix_html phoenix_template ];
    };

    plug = buildMix rec {
      name = "plug";
      version = "1.16.1";

      src = fetchHex {
        pkg = "plug";
        version = "${version}";
        sha256 = "a13ff6b9006b03d7e33874945b2755253841b238c34071ed85b0e86057f8cddc";
      };

      beamDeps = [ mime plug_crypto telemetry ];
    };

    plug_cowboy = buildMix rec {
      name = "plug_cowboy";
      version = "2.7.2";

      src = fetchHex {
        pkg = "plug_cowboy";
        version = "${version}";
        sha256 = "245d8a11ee2306094840c000e8816f0cbed69a23fc0ac2bcf8d7835ae019bb2f";
      };

      beamDeps = [ cowboy cowboy_telemetry plug ];
    };

    plug_crypto = buildMix rec {
      name = "plug_crypto";
      version = "2.1.0";

      src = fetchHex {
        pkg = "plug_crypto";
        version = "${version}";
        sha256 = "131216a4b030b8f8ce0f26038bc4421ae60e4bb95c5cf5395e1421437824c4fa";
      };

      beamDeps = [];
    };

    poison = buildMix rec {
      name = "poison";
      version = "4.0.1";

      src = fetchHex {
        pkg = "poison";
        version = "${version}";
        sha256 = "ba8836feea4b394bb718a161fc59a288fe0109b5006d6bdf97b6badfcf6f0f25";
      };

      beamDeps = [];
    };

    ranch = buildRebar3 rec {
      name = "ranch";
      version = "1.8.0";

      src = fetchHex {
        pkg = "ranch";
        version = "${version}";
        sha256 = "49fbcfd3682fab1f5d109351b61257676da1a2fdbe295904176d5e521a2ddfe5";
      };

      beamDeps = [];
    };

    ssl_verify_fun = buildRebar3 rec {
      name = "ssl_verify_fun";
      version = "1.1.7";

      src = fetchHex {
        pkg = "ssl_verify_fun";
        version = "${version}";
        sha256 = "fe4c190e8f37401d30167c8c405eda19469f34577987c76dde613e838bbc67f8";
      };

      beamDeps = [];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.3.0";

      src = fetchHex {
        pkg = "telemetry";
        version = "${version}";
        sha256 = "7015fc8919dbe63764f4b4b87a95b7c0996bd539e0d499be6ec9d7f3875b79e6";
      };

      beamDeps = [];
    };

    unicode_util_compat = buildRebar3 rec {
      name = "unicode_util_compat";
      version = "0.7.0";

      src = fetchHex {
        pkg = "unicode_util_compat";
        version = "${version}";
        sha256 = "25eee6d67df61960cf6a794239566599b09e17e668d3700247bc498638152521";
      };

      beamDeps = [];
    };

    websock = buildMix rec {
      name = "websock";
      version = "0.5.3";

      src = fetchHex {
        pkg = "websock";
        version = "${version}";
        sha256 = "6105453d7fac22c712ad66fab1d45abdf049868f253cf719b625151460b8b453";
      };

      beamDeps = [];
    };

    websock_adapter = buildMix rec {
      name = "websock_adapter";
      version = "0.5.7";

      src = fetchHex {
        pkg = "websock_adapter";
        version = "${version}";
        sha256 = "d0f478ee64deddfec64b800673fd6e0c8888b079d9f3444dd96d2a98383bdbd1";
      };

      beamDeps = [ plug plug_cowboy websock ];
    };
  };
in self

