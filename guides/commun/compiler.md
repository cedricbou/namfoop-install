# Compiler et installer namfoop

namfoop n'est pas encore distribué tout compilé : on le compile sur la machine qui va jouer. C'est
aussi ce qui donne le binaire le plus rapide, car le moteur des modèles est optimisé pour le
processeur exact de la machine (sur le Pi 5, son Cortex-A76).

## Récupérer ce dépôt

Avec git (le plus simple pour le mettre à jour ensuite par `git pull`) :

```sh
git clone https://github.com/cedricbou/namfoop-install.git
cd namfoop-install
```

Sur une machine neuve sans git, **DietPi par exemple**, qui n'a ni git ni zip : soit installer git
d'abord (`sudo apt install -y git`, le script l'installerait de toute façon), soit prendre l'archive
`.tar.gz`, que `curl` et `tar` savent ouvrir et qui garde les scripts exécutables (l'archive `.zip`
de GitHub les perd) :

```sh
curl -L https://github.com/cedricbou/namfoop-install/archive/refs/heads/main.tar.gz | tar xz
cd namfoop-install-main
```

## En une commande

Depuis ce dépôt :

```sh
scripts/namfoop-build
```

Le script :

1. installe les paquets nécessaires à la compilation (il les liste et demande avant) ;
2. installe [rustup](https://rustup.rs) s'il manque ; rustup prend tout seul la version de Rust que
   namfoop demande ;
3. télécharge la source de la version de namfoop suivie par les guides (fichier
   [`NAMFOOP_VERSION`](../../NAMFOOP_VERSION)), dans `~/.cache/namfoop-install/src` ;
4. compile namfoop, ce qui prend quelques minutes sur un PC, nettement plus sur le Pi ;
5. installe le binaire et vérifie que `namfoop --version` répond la bonne version.

**Relancer la commande ne recompile rien** si la bonne version est déjà installée. Pour voir où on
en est, sans rien changer :

```sh
scripts/namfoop-build status
```

## Les droits temps réel

En fin d'installation, le script propose de donner à ton utilisateur les droits dont namfoop a
besoin pour jouer sans craquement : passer son thread audio en priorité temps réel (FIFO 80),
verrouiller sa mémoire, accéder à la carte son et au MIDI, et sur le Pi lire l'alimentation et la
température. Sans eux, namfoop joue quand même, mais retombe sur une priorité plafonnée à 20 et des
buffers finissent par déborder.

Le même réglage, à part :

```sh
scripts/namfoop-rights status    # ce qui est réglé, et ce que la session en cours a reçu
scripts/namfoop-rights on        # le régler (une fois par utilisateur)
scripts/namfoop-rights off       # le retirer
```

| Système | Ce que fait `on` |
| :--- | :--- |
| EndeavourOS, Arch | installe `realtime-privileges`, ajoute l'utilisateur au groupe `realtime` (et `audio`) |
| DietPi, Debian, Ubuntu | écrit `/etc/security/limits.d/95-namfoop.conf` (priorité 95 et mémoire sans limite pour le groupe `audio`), ajoute l'utilisateur à `audio` ; sur le Pi, aussi à `video` |

**Les droits valent pour les sessions ouvertes ensuite** : se déconnecter puis se reconnecter,
SSH compris. `status` le dit si la session en cours ne les a pas encore reçus. Le service de
démarrage du Pi, lui, ne dépend pas de ce réglage : il pose ses propres limites.

## Les options

| Option | Effet |
| :--- | :--- |
| `--version v0.8.0` | une autre version de namfoop que celle des guides |
| `--prefix DIR` | installe dans `DIR/bin` ; par défaut `~/.local/bin` sur un PC, `/usr/local/bin` sur le Pi |
| `--portable` | binaire qui tourne sur tout processeur de la même famille, un peu moins rapide (utile pour copier le binaire ailleurs) |
| `--jobs N` | limite la compilation à N tâches en parallèle (moins de mémoire) |
| `--yes` | répond oui aux questions (installation sans surveillance) |
| `--dry-run` | montre ce qui serait fait, sans rien faire |
| `deps` | installe seulement les dépendances, sans compiler |

## Ce qui est installé, par système

| Système | Paquets |
| :--- | :--- |
| EndeavourOS, Arch | `base-devel git rustup alsa-lib` |
| DietPi, Debian, Ubuntu | `build-essential pkg-config git curl ca-certificates libasound2-dev`, puis rustup par son script officiel (dans `~/.cargo`) |

Pourquoi ces paquets : namfoop compile avec lui un moteur en C++ (d'où le compilateur C++ et
`pkg-config`), parle directement à la carte son par ALSA (d'où ses en-têtes), et se compile avec
Rust.

## Sur le Pi 5 : l'heure

Le Pi n'a pas de pile pour garder l'heure : au démarrage, il reprend celle de son dernier arrêt,
jusqu'à ce que le réseau la corrige. Tant qu'elle est en retard, les dépôts de paquets refusent
leurs signatures (« Not live until … ») et les téléchargements HTTPS échouent. Le script vérifie
donc l'heure avant de télécharger, et propose de relancer sa synchronisation
(`systemd-timesyncd`). Pour vérifier à la main : `timedatectl` doit dire
`System clock synchronized: yes`.

Sur DietPi, le réglage est dans `dietpi-config`, Advanced Options, Time sync mode. **Boot only**
convient à une machine de scène : l'heure est corrigée une fois au démarrage, puis plus rien ne
tourne pendant le jeu. Couper la synchronisation n'est pas utile contre les xruns : namfoop et ALSA
comptent le temps sur une horloge qui ne saute jamais, quel que soit le réglage de l'heure, et une
correction coûte quelques microsecondes. Sans réseau sur scène, l'heure reste celle du dernier
arrêt : une pile pour l'horloge du Pi 5 (connecteur RTC, pile officielle) la garde juste.

## Sur le Pi 5 : la mémoire

La dernière étape de compilation assemble tout le programme d'un bloc pour l'optimiser, et demande
plusieurs Go de mémoire. Avec moins de 3 Go libres (Pi 5 de 4 Go, par exemple), le script compile
sur un seul job : c'est plus long, mais ça aboutit. Si la compilation s'arrête quand même faute de
mémoire, ajoute temporairement de l'espace d'échange avec `dietpi-config` puis relance.

## Revenir en arrière

- Retirer namfoop : supprimer le binaire (`rm ~/.local/bin/namfoop`, ou `/usr/local/bin/namfoop`
  sur le Pi) et le cache `~/.cache/namfoop-install`.
- Revenir à une version précédente : `scripts/namfoop-build --version vX.Y.Z`.
- Les paquets installés restent : ils ne gênent rien, et servent à la prochaine mise à jour.

Ta bibliothèque de sons et ta config ne sont jamais touchées par ce script.
