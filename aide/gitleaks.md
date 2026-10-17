# gitleaks : chercher les secrets (mots de passe, jetons, clés)

dotf s'en sert à chaque commit et push de son dépôt (dotf scan). On peut aussi l'utiliser sur ses projets.

## Commandes
    gitleaks git                 tout l'historique du dépôt courant
    gitleaks git -v              en montrant chaque fuite trouvée
    gitleaks git --staged --pre-commit    seulement ce qui est prêt à être commité
    gitleaks git --log-opts="-5"          les 5 derniers commits
    gitleaks git --log-opts="main..HEAD"  les commits de la branche, pas encore dans main
    gitleaks dir .               les fichiers du dossier, sans l'historique (dossier hors git, archive…)
    gitleaks dir --redact -v .   même chose, en masquant les secrets dans l'affichage
    gitleaks git -r rapport.json un rapport JSON

Code de sortie : 0 rien trouvé, 1 fuite trouvée (utilisable dans un script ou un hook).

## Faux positifs
    ligne … # gitleaks:allow     ignore cette ligne
    .gitleaksignore              une empreinte (« Fingerprint » affichée par -v) par ligne à ignorer
Dans le dépôt dotf, « dotf-allow » fait taire le contrôle propre à dotf ; pour gitleaks, c'est « gitleaks:allow ».

## Si un secret a été poussé
Le supprimer dans un nouveau commit ne suffit pas : il reste dans l'historique et les copies.
Le révoquer et le régénérer chez le fournisseur (GitHub, AWS…), puis seulement nettoyer.

## Exemples
    cd ~/projets/site && gitleaks git -v     avant de rendre un dépôt public
    gitleaks dir -v ~/Téléchargements/projet     code reçu, avant de le versionner
