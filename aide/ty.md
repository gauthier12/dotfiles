# ty : vérifier les types Python (et aider nvim)

ty lit les annotations (x: int, def f(nom: str) -> str) et signale ce qui ne colle pas. Dans nvim, il fournit
la complétion, K, Ctrl-] et grr en Python (« dotf help nvim ») ; ruff garde les imports, le style et le formatage.

## Vérifier
    ty check                     tout le projet (dossier courant et sous-dossiers)
    ty check script.py           un fichier
    ty check --watch             revérifier à chaque enregistrement
    ty check --output-format concise   une ligne par erreur
    ty explain rule invalid-assignment explication d'une règle

## Bibliothèques installées (numpy, requests…)
ty prend l'environnement virtuel actif ($VIRTUAL_ENV), sinon le .venv à la racine du projet.
    ty check --python .venv      en indiquer un autre

## Ignorer
    x = f()  # ty: ignore[invalid-assignment]   cette erreur sur cette ligne
    ty check --add-ignore        ajouter ces commentaires partout (vieux code non annoté)

## Régler le projet (pyproject.toml)
    [tool.ty.rules]
    possibly-unresolved-reference = "warn"   # error, warn ou ignore

## Exemples
    x: int = "a"                 → Object of type `str` is not assignable to `int`
    python -m venv .venv && .venv/bin/pip install requests && nvim main.py
                                 import requests ; requests.  → la complétion propose get, post…
    ruff check --fix && ruff format && ty check   avant un commit
