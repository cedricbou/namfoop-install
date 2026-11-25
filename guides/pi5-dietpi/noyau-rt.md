# Le noyau temps réel du Pi 5

Sur scène, le noyau temps réel (PREEMPT_RT) est **obligatoire** : il réveille le thread audio de
namfoop à l'heure même quand le reste de la machine travaille. Sans lui, un réveil en retard de
quelques centaines de microsecondes de temps en temps suffit à faire déborder un buffer d'une
milliseconde, et on l'entend.

Mesure de référence : Pi 5 de 8 Go, DietPi, noyau `6.18.60+rpt-rpi-v8-rt`, sans cœur réservé, les
trois autres cœurs chargés à fond (`scripts/namfoop-doctor --measure --load`), 25 novembre 2026 :
**retard maximal 7 µs** en 60 s.

## Quelle voie

| Voie | Mises à jour | Retour au noyau standard | Ce qu'elle coûte |
| :--- | :--- | :--- | :--- |
| **Paquet temps réel de Raspberry Pi** (`linux-image-rpi-v8-rt`) : retenue | suit `apt upgrade`, comme le noyau standard | une ligne de `config.txt` à retirer | rien à compiler ; noyau « v8 » (voir plus bas) |
| Noyau compilé soi-même (source Raspberry Pi, `CONFIG_PREEMPT_RT=y`) | tout recompiler à chaque correctif, sinon il vieillit sans correctifs de sécurité | même geste | des heures de compilation, un noyau à maintenir ; le publier obligerait à publier aussi sa source exacte et sa configuration (GPL-2.0) |
| Noyau temps réel de Debian (`linux-image-rt-arm64`) | suit `apt upgrade` | même geste | écarté : noyau générique, sans les réglages ni tous les pilotes propres au Pi 5 |

Le paquet de Raspberry Pi vient du même dépôt que le noyau standard du Pi, il est construit avec
les mêmes pilotes, et il s'installe **à côté** du noyau standard : rien n'est perdu, et la mesure
ci-dessus montre qu'il suffit largement.

### « v8 » ou « 2712 »

Le Pi 5 a deux noyaux standard : « v8 », commun aux Pi 64 bits, avec des pages mémoire de 4 Ko, et
« 2712 », propre au Pi 5, avec des pages de 16 Ko, un peu plus rapide en calcul. Le paquet temps réel
utilisé ici est un « v8 ». Le diagnostic le signale à titre d'information. Si un paquet temps réel
« 2712 » est publié, le comparer avec `namfoop bench` (le coût de calcul des modèles) et avec la
mesure du diagnostic avant d'en changer.

## Installer

Depuis le Pi, connecté à internet (l'heure doit être juste, voir « Compiler et installer ») :

```sh
sudo apt update
sudo apt install linux-image-rpi-v8-rt
```

Puis dire au Pi de démarrer dessus : ajouter à la fin de `/boot/firmware/config.txt` (garder une
copie avant : `sudo cp -p /boot/firmware/config.txt /boot/firmware/config.txt.avant-noyau-rt`) :

```ini
kernel=kernel8_rt.img
```

Redémarrer, puis vérifier :

```sh
uname -r                 # finit par -rt
scripts/namfoop-doctor   # « noyau temps réel (PREEMPT_RT) » en ✓
```

## Mettre à jour

`sudo apt update && sudo apt upgrade` met à jour le noyau temps réel comme le reste. Après le
redémarrage, `uname -r` donne la nouvelle version. Une fois le système protégé en écriture, le
déverrouiller d'abord : une mise à jour du noyau écrit dans `/boot/firmware`.

## Revenir au noyau standard

Dans cet ordre, pour toujours garder un noyau qui démarre :

1. retirer (ou commenter avec `#`) la ligne `kernel=kernel8_rt.img` de `/boot/firmware/config.txt` ;
2. redémarrer : `uname -r` ne finit plus par `-rt` ;
3. seulement ensuite, si on veut, désinstaller : `sudo apt purge linux-image-rpi-v8-rt`.

**Si le Pi ne démarre plus** sur le noyau temps réel : la première partie de la carte SD (en FAT) se lit
sur n'importe quel ordinateur. Y ouvrir `config.txt` et retirer la ligne `kernel=…` : le Pi
redémarre sur son noyau standard.
