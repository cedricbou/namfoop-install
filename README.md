# namfoop-install

Installer, régler et lancer [namfoop](https://github.com/cedricbou/namfoop) — le multi-effet basse
temps réel en ligne de commande — sur chaque système, avec des guides pas à pas et des scripts qui
font le travail répétitif.

Ce dépôt ne contient pas namfoop : il le compile à partir d'une version publiée, règle la machine
autour de lui et le lance. Il ne contient aucun son non plus : modèles NAM, IR et packs restent chez
toi.

## Choisir son guide

| Sujet | Raspberry Pi 5 (DietPi) | EndeavourOS / Arch | Ubuntu | macOS, Windows |
| :--- | :--- | :--- | :--- | :--- |
| Compiler et installer namfoop | [essayé](guides/commun/compiler.md) | [essayé](guides/commun/compiler.md) | plus tard | quand namfoop le permettra |
| Bibliothèque de sons au bon endroit | [écrit](guides/commun/bibliotheque.md), essai à faire | [écrit](guides/commun/bibliotheque.md), essai à faire | plus tard | — |
| Réglages temps réel du système | à écrire, poussés au maximum | à écrire, réversibles | plus tard | — |
| Noyau PREEMPT_RT | **obligatoire** | en option | plus tard | — |
| Plein écran sans bureau (cage + foot) | au démarrage | à la demande (mode scène) | plus tard | — |
| Système protégé en écriture | à écrire | — | — | — |
| Démarrage automatique, reprise après coupure | à écrire | — | — | — |
| Carte son HAT | plus tard | — | — | — |

Les guides : [`guides/`](guides/). Chaque guide indique la version de namfoop qu'il suit :
[`VERSIONS.md`](VERSIONS.md).

## Deux cibles, deux logiques

- **Raspberry Pi 5 sous DietPi** : la machine de scène. Elle ne fait que namfoop, démarre seule,
  tourne sur un noyau temps réel, garde son système protégé en écriture et ses sons, instruments et
  calibrations sur une partie inscriptible.
- **EndeavourOS** : le poste de création, qui sert aussi à jouer. Tout réglage se défait : un mode
  scène quitte le bureau le temps de jouer, puis le rend.

## Les scripts

Dans `scripts/`. Tous suivent les mêmes règles :

- **relancer ne change rien** : un script déjà appliqué le dit et s'arrête ;
- `status` montre l'état sans rien toucher ; `--dry-run` montre ce qui serait fait ;
- tout ce qui modifie le système a son retour arrière (`off`) ;
- aucun ne redémarre la machine sans le demander, aucun ne joue de son.

## Licence

Copyright (C) 2026 les contributeurs de namfoop-install.

Ce dépôt est un logiciel libre sous **GPL-3.0-or-later** ([`LICENSE`](LICENSE)), comme namfoop : on
peut utiliser, étudier, modifier et redistribuer ses guides et ses scripts, à condition qu'une
version redistribuée, modifiée ou non, reste sous la même licence avec sa source. Chaque script le
rappelle en tête (`SPDX-License-Identifier: GPL-3.0-or-later`).

Ce que les scripts installent ou téléchargent n'est pas redistribué par ce dépôt et garde sa propre
licence : namfoop (GPL-3.0-or-later), DietPi (GPL-2.0), le noyau Linux (GPL-2.0), cage (MIT), foot
(MIT), dtach (GPL-2.0-or-later), la police JetBrains Mono (SIL OFL 1.1). Les modèles et IR ne sont
jamais distribués : chaque pack garde la licence de son auteur.

Un fichier repris d'un autre projet garde sa licence d'origine, indiquée en tête du fichier, et est
listé ici :

| Fichier | Origine | Licence |
| :--- | :--- | :--- |
| *(aucun pour l'instant)* | | |
