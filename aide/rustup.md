# Rust : rustup (versions) et cargo (projets)

Installé dans ~/.cargo et ~/.rustup, avec rust-analyzer, clippy et rustfmt.
Dans nvim : complétion, erreurs de clippy et formatage à l'enregistrement (voir « dotf help nvim »).

## rustup
    rustup update                mettre Rust à jour (dotf update le fait aussi)
    rustup show                  version active
    rustup doc --std             documentation de la bibliothèque standard (hors ligne)
    rustup doc --book            le livre « The Rust Programming Language »
    rustup toolchain install nightly      installer nightly ; cargo +nightly build pour s'en servir

## cargo
    cargo new essai              nouveau programme (cargo new --lib pour une bibliothèque)
    cargo run                    compiler et lancer ;  cargo run -- arg1 arg2  avec des arguments
    cargo check                  vérifier sans produire de binaire (rapide)
    cargo build --release        binaire optimisé, dans target/release/
    cargo test                   tests ;  cargo test nom  ceux dont le nom contient « nom »
    cargo clippy                 conseils et pièges (cargo clippy --fix pour appliquer)
    cargo fmt                    mettre en forme
    cargo add serde --features derive     ajouter une dépendance
    cargo doc --open             documentation du projet et de ses dépendances
    cargo install ripgrep        installer un outil (dans ~/.cargo/bin)
    cargo clean                  supprimer target/ (souvent plusieurs Go)

## Exemple
    cargo new essai && cd essai
    cargo add rand
    nvim src/main.rs             écrire, :w (formaté, clippy vérifie)
    cargo run
