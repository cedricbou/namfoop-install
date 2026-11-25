# Ranger sa bibliothèque de sons

namfoop range tes modèles NAM, tes IR, tes presets, tes sets et tes instruments calibrés dans un
dossier : la **bibliothèque**. Lancé depuis un terminal, un service de démarrage ou la console de
scène, il doit la retrouver sans qu'on lui dise où elle est. Le plus sûr est d'écrire son chemin
une fois pour toutes dans la config de namfoop : c'est ce que fait ce script.

## En deux commandes

```sh
scripts/namfoop-library init                      # crée la bibliothèque et l'écrit dans la config
scripts/namfoop-library import ~/Téléchargements/ # y range chaque zip de ce dossier
```

Puis, pour vérifier, sans rien changer :

```sh
scripts/namfoop-library status
```

`status` dit quelle bibliothèque la config désigne, combien elle contient de modèles et d'IR, si
elle est inscriptible, et si namfoop la trouve **depuis n'importe quel dossier**.

## Où elle va

| Machine | Emplacement | Pourquoi |
| :--- | :--- | :--- |
| PC (EndeavourOS…) | `~/.local/share/namfoop/library` | l'emplacement par défaut de namfoop, dans ton dossier personnel |
| Pi 5 (DietPi) | `/mnt/dietpi_userdata/namfoop/library` | le dossier de données de DietPi, qui restera inscriptible quand le système sera protégé en écriture, et peut aller sur une clé ou un SSD |

Sur le Pi, la bibliothèque doit rester inscriptible pendant le concert : namfoop y enregistre aussi
tes instruments et leurs calibrations, y compris quand tu calibres au pied sur scène.

Pour la mettre ailleurs : `scripts/namfoop-library init --path /chemin/de/ma/bibliotheque`.

## Ce que fait `init`

1. crée le dossier s'il n'existe pas ; **une bibliothèque existante n'est jamais déplacée ni
   vidée** ;
2. écrit `library = "<chemin>"` en tête de la config de namfoop
   (`~/.config/namfoop/config.toml`, ou `--config FICHIER`), après en avoir gardé une copie à côté
   (`config.toml.avant-namfoop-library.<date>`) ;
3. si la config désignait déjà une autre bibliothèque, demande avant de changer. L'ancienne reste
   où elle est, intacte.

Relancer `init` ne change rien.

## Ce que fait `import`

Il confie le travail à `namfoop import` : chaque zip, dossier, `.nam` ou `.wav` est rangé dans
son pack, vérifié (un modèle illisible ou une IR muette est refusé), et rien de ce qui est déjà
dans la bibliothèque n'est écrasé. Relancer l'import ne change rien.

```sh
scripts/namfoop-library import --dry-run ~/Téléchargements/    # vérifie tout sans rien écrire
scripts/namfoop-library import pack.zip -- --pack "Mes IR"     # après --, les options de namfoop import
```

Le détail (types de capture, fichiers identiques, IR conseillées) est dans le guide de namfoop,
§ 6 « La bibliothèque de sons ».

## Revenir en arrière

- La config d'avant est dans `config.toml.avant-namfoop-library.<date>` : la remettre à la place
  de `config.toml`.
- Sans clé `library`, namfoop reprend sa règle : `./library` s'il existe dans le dossier courant,
  sinon `~/.local/share/namfoop/library`.
- Le script ne supprime jamais de son : retirer un pack, c'est supprimer son dossier à la main.
