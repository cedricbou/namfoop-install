# Vérifier que la machine est prête à jouer

Un réglage oublié (droits temps réel, gouverneur, module MIDI) ne se voit pas tant qu'on ne joue
pas, puis s'entend en répétition sous forme de craquements. Le diagnostic les passe tous en revue,
sans rien modifier (seule la mesure, plus bas, peut installer ses outils, après avoir demandé) :

```sh
scripts/namfoop-doctor
```

Chaque ligne dit :

- `✓` : bon ;
- `✗` : à corriger, avec, en dessous, la commande ou le guide qui corrige (les droits temps réel,
  par exemple : `scripts/namfoop-rights on`) ;
- `·` : pour information, ou sans objet sur cette machine (un cœur réservé est facultatif sur un
  PC, obligatoire sur le Pi de scène).

Le code de sortie vaut 0 quand rien n'est à corriger : on peut l'enchaîner dans un script.

## Ce qui est vérifié, et pourquoi

| Point | Pourquoi ça compte |
| :--- | :--- |
| Noyau PREEMPT_RT | réveille le thread audio à l'heure même quand la machine travaille ; obligatoire sur le Pi de scène, facultatif sur le PC |
| Heure synchronisée | en retard (Pi sans pile, juste démarré), elle fait refuser les paquets et les téléchargements |
| Priorité temps réel ≥ 80 | namfoop met son thread audio en FIFO 80 ; sans ce droit il retombe sur rtkit, plafonné à 20, et des buffers débordent ; par SSH sur DietPi, Dropbear ne les transmet pas (voir « Compiler et installer », droits temps réel) |
| Mémoire verrouillable sans limite | namfoop verrouille sa mémoire : aucun défaut de page en jouant |
| Gouverneur `performance` | sinon la fréquence redescend entre deux buffers et la charge fait des pics |
| Cœur réservé (`isolcpus`, `nohz_full`, `irqaffinity`) | un cœur pour le son seul ; namfoop s'y épingle avec `--cpu N` |
| Interruptions USB | leur priorité face au thread audio (FIFO 80), affichée pour la mesure |
| Pi : alimentation, chauffe, courant USB (par `vcgencmd`, qui demande le groupe `video`) | un Pi bridé ralentit ; sans l'alimentation officielle, l'USB est limité à 600 mA pour la carte son et le pédalier |
| Pi : swap coupé | rien n'écrit sur la carte SD à l'improviste |
| Pi : protection en écriture, partie de données | le système protégé, les sons et calibrations inscriptibles |
| Carte son, accès à `/dev/snd` | namfoop parle directement à la carte |
| Séquenceur MIDI (`snd-seq`) | sans lui, ni pédalier ni horloge |
| namfoop et sa bibliothèque | le binaire, sa version, et des sons trouvés depuis n'importe quel dossier |

Ce que namfoop vérifie lui-même au démarrage (priorité obtenue, mémoire verrouillée, gouverneur), il
le redit en lançant `namfoop run` : le diagnostic sert à corriger **avant**.

## Mesurer, sans jouer de son

```sh
scripts/namfoop-doctor --measure
```

Ajoute une mesure de 60 s avec `cyclictest` : il se réveille toutes les 200 µs sur le cœur du son, à
la priorité du thread audio, et note le retard de chaque réveil. Avec un buffer de 48 frames à
48 kHz, namfoop a 1 000 µs par bloc ; un retard de plus de 300 µs en mange une part qu'on entendra
tôt ou tard.

- jusqu'à 100 µs : `✓` ;
- de 100 à 300 µs : jouable, marge réduite ;
- au-delà : `✗`.

Pour mesurer machine chargée, comme sur scène :

```sh
scripts/namfoop-doctor --measure --load
```

`--load` fait tourner `stress-ng` à fond sur tous les autres cœurs pendant la mesure, puis
l'arrête. `--duration S` change la durée, `--core N` le cœur mesuré (par défaut, le dernier cœur
réservé, sinon le dernier cœur).

La mesure se termine par un bloc **« À coller dans une issue »** : machine, noyau, date, version de
namfoop, chiffres et état de chaque point.

`cyclictest` vient du paquet `rt-tests`, `stress-ng` du paquet du même nom : s'ils manquent, la
mesure propose de les installer (`--yes` pour ne pas demander).

## Et la latence aller-retour ?

`namfoop latency` mesure l'aller-retour réel de la carte, mais **il émet des clics** et demande un
câble d'une sortie vers une entrée : il reste un geste à part, volume baissé (guide de namfoop,
§ 15 « Mesurer la latence »).
