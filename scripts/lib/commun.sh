# shellcheck shell=bash
# Fonctions partagées par les scripts : journal, détection du système, mode --dry-run.
# À sourcer : . "$(dirname "$0")/lib/commun.sh"

DRY_RUN=${DRY_RUN:-0}

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

# Identifie la cible : pi5-dietpi, endeavouros, arch, ubuntu ou inconnu.
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
  else
    echo inconnu
  fi
}

# Vrai si le noyau en cours est PREEMPT_RT.
kernel_is_rt() {
  uname -v | grep -q 'PREEMPT_RT'
}
