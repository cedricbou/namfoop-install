# shellcheck shell=bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 les contributeurs de namfoop-install
# Fonctions partagées par les scripts : journal, détection du système, mode --dry-run.
# À sourcer : . "$(dirname "$0")/lib/commun.sh"

DRY_RUN=${DRY_RUN:-0}
YES=${YES:-0}
ARGS=()

info() { printf '  %s\n' "$*"; }
ok() { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ⚠ %s\n' "$*" >&2; }
die() {
  printf '  ✗ %s\n' "$*" >&2
  exit 1
}

# Exécute une commande qui modifie le système, ou l'affiche seulement en --dry-run.
run() {
  if ((DRY_RUN)); then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# Retire --dry-run des arguments et positionne DRY_RUN ; les autres arguments sont rendus dans ARGS.
parse_common_args() {
  ARGS=()
  for a in "$@"; do
    case $a in
      --dry-run) DRY_RUN=1 ;;
      *) ARGS+=("$a") ;;
    esac
  done
}

# Identifie la cible : pi5-dietpi, endeavouros, arch, ubuntu, debian ou inconnu.
detect_target() {
  local id="" like=""
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    id=$(. /etc/os-release && echo "${ID:-}")
    # shellcheck disable=SC1091
    like=$(. /etc/os-release && echo "${ID_LIKE:-}")
  fi
  if [[ -d /boot/dietpi ]] && grep -qs 'Raspberry Pi 5' /proc/device-tree/model; then
    echo pi5-dietpi
  elif [[ $id == endeavouros ]]; then
    echo endeavouros
  elif [[ $id == arch || $like == *arch* ]]; then
    echo arch
  elif [[ $id == ubuntu ]]; then
    echo ubuntu
  elif [[ $id == debian || $like == *debian* ]]; then
    echo debian
  else
    echo inconnu
  fi
}

# Vrai si le noyau en cours est PREEMPT_RT.
kernel_is_rt() {
  uname -v | grep -q 'PREEMPT_RT'
}

# Demande confirmation. Oui d'office avec --yes (YES=1) ou en --dry-run ; sans terminal et sans
# --yes, refuse au lieu de bloquer.
confirm() {
  if ((${YES:-0} || DRY_RUN)); then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    warn "$1 — pas de terminal pour répondre : relancer avec --yes"
    return 1
  fi
  local answer
  read -r -p "  $1 [o/N] " answer
  [[ $answer == [oOyY]* ]]
}

# Version de namfoop suivie par les guides : le fichier NAMFOOP_VERSION à la racine du dépôt.
default_namfoop_version() {
  local root=$1
  tr -d '[:space:]' <"$root/NAMFOOP_VERSION"
}

# Vrai si l'horloge est synchronisée par le réseau, ou si on ne peut pas le savoir (pas de systemd).
clock_synced() {
  local v
  v=$(timedatectl show -p NTPSynchronized --value 2>/dev/null) || return 0
  [[ -z $v || $v == yes ]]
}

# Une horloge en retard fait refuser les signatures des dépôts (« Not live until … ») et les
# certificats HTTPS (git clone). Le Pi n'a pas de pile : au démarrage, son heure est celle du dernier
# arrêt jusqu'à ce que le réseau la corrige. Si systemd-timesyncd tient l'heure, on relance la
# synchronisation et on attend 30 s au plus ; sinon on prévient seulement.
ensure_clock() {
  clock_synced && return 0
  warn "l'heure de la machine n'est pas synchronisée par le réseau : $(date '+%F %T %Z')"
  info "si elle est en retard, les dépôts de paquets et git refuseront de télécharger (« Not live until … »)"
  if ! systemctl is-enabled --quiet systemd-timesyncd 2>/dev/null; then
    if [[ -d /boot/dietpi ]]; then
      warn "synchronisation de l'heure coupée : dietpi-config, Advanced Options, Time sync mode, « Boot only » (une fois au démarrage, rien pendant le jeu) ; ou à la main : sudo date -s \"AAAA-MM-JJ HH:MM\""
    else
      warn "vérifie l'heure avec « date » ; « timedatectl » dit comment elle est tenue"
    fi
    return 0
  fi
  if ! confirm "Relancer la synchronisation de l'heure (systemd-timesyncd) ?"; then
    warn "on continue avec l'heure actuelle"
    return 0
  fi
  if ((DRY_RUN)); then
    info "[dry-run] sudo systemctl restart systemd-timesyncd, puis attente de la synchronisation"
    return 0
  fi
  if ((EUID == 0)); then systemctl restart systemd-timesyncd; else sudo systemctl restart systemd-timesyncd; fi
  local i
  for ((i = 0; i < 30; i++)); do
    if clock_synced; then
      ok "heure synchronisée : $(date '+%F %T %Z')"
      return 0
    fi
    sleep 1
  done
  warn "heure toujours pas synchronisée après 30 s : vérifie le réseau (sur DietPi : dietpi-config, Advanced Options, Time sync mode)"
}
