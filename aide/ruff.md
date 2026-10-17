# ruff : vérifier et mettre en forme du Python

Remplace flake8, isort, pyupgrade et black, en beaucoup plus rapide. Dans nvim, il tourne tout seul
(erreurs en fin de ligne, formatage à l'enregistrement : voir « dotf help nvim »).

## Vérifier
    ruff check                   tout le projet (dossier courant et sous-dossiers)
    ruff check script.py         un fichier
    ruff check --fix             corriger ce qui peut l'être sans risque
    ruff check --watch           revérifier à chaque enregistrement
    ruff check --statistics      nombre d'erreurs par règle
    ruff check --select I --fix  trier les imports seulement
    ruff rule F401               explication d'une règle (ici : import inutilisé)

## Mettre en forme
    ruff format                  tout le projet
    ruff format --diff           montrer ce qui changerait, sans rien modifier
    ruff format --check          code de sortie 1 si un fichier n'est pas en forme (CI)

## Ignorer
    x = f()  # noqa: F841        ignorer une règle sur cette ligne
    # ruff: noqa: E501           en tête de fichier : pour tout le fichier

## Régler le projet (pyproject.toml)
    [tool.ruff]
    line-length = 100
    [tool.ruff.lint]
    select = ["E", "F", "I", "UP", "B"]   # erreurs, pyflakes, imports, modernisation, pièges courants

## Exemples
    ruff check --fix && ruff format       avant un commit : corrige et met en forme
    ruff check --select UP --fix          moderniser un vieux code (f-strings, typing…)
