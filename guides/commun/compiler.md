# Compiler et installer namfoop

namfoop n'est pas encore distribué tout compilé : on le compile sur la machine qui va jouer. C'est
aussi ce qui donne le binaire le plus rapide, car le moteur des modèles est optimisé pour le
processeur exact de la machine (sur le Pi 5, son Cortex-A76).

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
