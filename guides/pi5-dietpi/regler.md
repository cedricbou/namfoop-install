# Régler le Pi 5 pour jouer sans craquement

On part d'un DietPi standard, fraîchement installé sur le Pi 5, branché au réseau par câble. Une
commande installe namfoop et règle tout le Pi pour lui. Chaque réglage se défait, et chaque fichier
modifié est copié avant.

## Le matériel

- **Un ventilateur actif** (l'Active Cooler officiel) : sans lui, le Pi ralentit dès qu'il chauffe,
  et la charge fait des pics.
- **L'alimentation officielle 5 V / 5 A** : le Pi la reconnaît et donne alors jusqu'à 1,6 A à l'USB.
  Avec une autre, l'USB est limité à 600 mA pour la carte son et le pédalier.
- **La carte son sur un port USB 3 (bleu)**, clavier et pédalier sur les ports USB 2 (noirs).

## En une commande

Connecté en `dietpi` (pas en `root`) :

```sh
sudo apt install -y git
git clone https://github.com/cedricbou/namfoop-install.git
cd namfoop-install
scripts/namfoop-pi install
sudo reboot
```

`install` enchaîne, en demandant avant chaque étape qui modifie le système :

1. namfoop compilé pour le processeur du Pi (guide « Compiler et installer ») ;
2. les droits temps réel de l'utilisateur ;
3. la bibliothèque de sons sur la partie de données, `/mnt/dietpi_userdata/namfoop/library` ;
4. les réglages du Pi, ci-dessous.

Le script ne redémarre jamais seul. Après le redémarrage, vérifier :

```sh
cd ~/namfoop-install
scripts/namfoop-pi status
scripts/namfoop-doctor --measure --load
```

Relancer `install` ou `on` ne refait rien de ce qui est déjà posé.

## Les réglages, et pourquoi

| Réglage | Ce que fait `namfoop-pi on` | Pourquoi |
| :--- | :--- | :--- |
| `noyau` | installe `linux-image-rpi-v8-rt`, ajoute `kernel=kernel8_rt.img` à `config.txt` | le thread audio se réveille à l'heure même machine chargée (guide du noyau temps réel) |
| `coeur` | ajoute `isolcpus=3 nohz_full=3 rcu_nocbs=3 irqaffinity=0-2` à `cmdline.txt` | le cœur 3 ne fait plus que le son : le système et les interruptions vont sur les cœurs 0 à 2 ; namfoop s'y épingle avec `--cpu 3` |
| `gouverneur` | `CONFIG_CPU_GOVERNOR=performance` dans `dietpi.txt`, appliqué tout de suite | la fréquence ne redescend pas entre deux buffers |
| `irq` | installe `rtirq-init`, `RTIRQ_NAME_LIST="xhci usb snd"` dans `/etc/default/rtirq` | les interruptions USB, par où passent le son et le MIDI, passent avant le thread audio (FIFO 80) |
| `swap` | coupe le fichier d'échange (outil de DietPi) | rien n'écrit sur la carte SD à l'improviste ; namfoop verrouille déjà sa mémoire |
| `chauffe` | `temp_limit=85` dans `config.txt` | le Pi ne ralentit qu'à 85 °C, la limite du constructeur, et non plus tôt (DietPi peut la régler à 75 °C) ; avec un ventilateur actif seulement |

Avec `--scene`, pour la machine de scène (`scripts/namfoop-pi on --scene`) :

| Réglage | Ce que fait `on` | Pourquoi, et ce que ça coûte |
| :--- | :--- | :--- |
| `radio` | `dtoverlay=disable-wifi` et `disable-bt` dans `config.txt` | moins d'interruptions ; **SSH par câble seulement** : le script refuse si la session passe par le Wi-Fi |
| `leds` | voyants d'activité et d'alimentation éteints | plus rien ne clignote sur scène |
| `clavier` | `usbhid.kbpoll=64` dans `cmdline.txt` | le clavier interrompt six fois moins souvent ; il réagit un peu moins vite |

Les lignes de `config.txt` vont dans un bloc à la fin du fichier, entre deux commentaires
`namfoop-install`. Dans `config.txt`, la dernière valeur d'un réglage l'emporte : retirer le bloc rend
les réglages d'avant.

## Voir, poser, retirer

```sh
scripts/namfoop-pi status            # chaque réglage : posé, actif, ou au prochain démarrage
scripts/namfoop-pi on                # les six réglages de base
scripts/namfoop-pi on coeur chauffe  # seulement ceux-là
scripts/namfoop-pi off               # retire tout ce que le script a posé
scripts/namfoop-pi off radio         # seulement le Wi-Fi et le Bluetooth
```

`off` ne retire que ce que le script a posé : un réglage déjà là avant (posé à la main, ou par
`dietpi-config`) reste. Les paquets installés (`linux-image-rpi-v8-rt`, `rtirq-init`) restent, sans
effet une fois le réglage retiré. Chaque fichier modifié est copié à côté de lui avant :
`config.txt.avant-namfoop-pi.<date>`. Ce que le script a posé est noté dans
`/var/lib/namfoop-install/pi`.

**Si le Pi ne démarre plus** après un réglage : la première partie de la carte SD (en FAT) se lit
sur n'importe quel ordinateur. Y remettre la copie `config.txt.avant-namfoop-pi.<date>` (ou
`cmdline.txt…`) à la place du fichier.

## Recompiler namfoop sur un Pi de 4 Go

La compilation a besoin du fichier d'échange sur un Pi de 4 Go. `install` compile avant de le
couper. Pour recompiler plus tard (nouvelle version de namfoop) :

```sh
scripts/namfoop-pi off swap
scripts/namfoop-build
scripts/namfoop-pi on swap
```

## Ce que le script ne fait pas

- `usb_max_current_enable=1` : forcer 1,6 A sur l'USB n'est sûr qu'avec l'alimentation officielle,
  que le Pi reconnaît déjà seul.
- Couper l'Ethernet : c'est par lui qu'on rejoint le Pi en SSH. Sur scène, `dietpi-config`, Network
  Options.
- Le serveur SSH : Dropbear, celui de DietPi, suffit sur scène, mais ne transmet pas les droits temps
  réel aux sessions (guide « Compiler et installer ») ; OpenSSH les transmet.
- L'heure : `dietpi-config`, Advanced Options, Time sync mode, « Boot only » (guide « Compiler et
  installer »).
