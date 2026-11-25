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
