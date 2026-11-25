# CLAUDE.md — namfoop-install

Guides et scripts pour installer, régler et lancer namfoop sur chaque système. **La fiabilité en
live et la latence priment sur tout**, comme dans namfoop. Doc utilisateur : `README.md`.

## Ce dépôt et namfoop

- namfoop est un programme **qu'on installe**, pas une dépendance qu'on modifie : ce dépôt ne
  change rien au dépôt namfoop, n'y ouvre ni issue ni PR, et n'y fait pas référence.
- On compile toujours **un tag** de namfoop, jamais `main` ; la version suivie est dans
  `VERSIONS.md`.
- Ce que namfoop sait faire ou vérifier lui-même (priorité temps réel, memlock, gouverneur, chemin
  de la bibliothèque), on le lit dans son guide (`docs/guide.md` du tag suivi) au lieu de le
  redécrire.

## Carte

```
guides/commun/        ce qui vaut pour tout Linux : compiler, bibliothèque, temps réel, console
guides/pi5-dietpi/    la machine de scène : image, noyau RT, réglages, écriture, démarrage, HAT
guides/endeavouros/   le poste de création : mode scène, PREEMPT_RT en option
scripts/              un script par geste ; scripts/lib/commun.sh pour ce qu'ils partagent
config/               units systemd, foot.ini, limits.d, udev, fragments de démarrage
```

## Règles des scripts (non négociables)

- Bash, `set -euo pipefail`, `scripts/lib/commun.sh` pour le journal, la détection du système,
  `--dry-run` et les confirmations ; `shellcheck` sans avertissement (la CI le vérifie).
- **Idempotents** : relancer ne change rien. Chaque script a `status` ; tout ce qui modifie le
  système a son retour arrière (`off` / `revert`) et garde une copie de ce qu'il remplace.
- Jamais de redémarrage sans le demander. Jamais de son joué : on vérifie avec
  `namfoop run --master-db -120` ou la carte simulée (`--backend sim`).
- Ne lisent pas, ne copient pas, ne versionnent jamais une bibliothèque de sons (`library/`, `nam/`,
  `.nam`, `.wav`) : les droits appartiennent à leurs auteurs.
- Un agent n'a ni Pi ni carte son : il teste en `--dry-run`, dans un conteneur ou sur la carte
  simulée, et demande l'essai matériel à l'utilisateur.

## Cycle

issue → branche (`feat|fix|docs/<n°>-…`) → PR « Closes #n » → CI verte → squash merge. Jamais de
commit direct sur `main`. Une issue dont il ne reste que l'essai sur le matériel reste ouverte avec
l'étiquette `essai-materiel`.

**Les issues s'écrivent pour le bassiste** : un titre qui dit ce qu'il veut pouvoir faire, un corps
« En tant que… je veux… afin de… », une rubrique « Terminé quand » qui s'observe sur la machine. Le
détail technique (paquets, fichiers, pistes, mesures) va dans un commentaire `## Cadrage technique`.
Étiquettes de type : `epic`, `story`, `etude` (à trancher avant de coder), `chore`, `bug` ; de cible :
`pi5`, `endeavouros`, `commun`.

## Conventions

- Tout en **français** : guides, messages des scripts, commentaires ; identifiants en anglais.
- Un guide dit **le pourquoi** de chaque réglage et **comment revenir en arrière**.
- Un fait mesuré (latence, `cyclictest`, chauffe) donne la machine, le noyau et la date, et
  **remplace** le précédent au lieu de s'empiler.
