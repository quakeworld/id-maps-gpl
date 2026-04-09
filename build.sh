#!/bin/bash
set -euo pipefail

MAPS=(
  dm1 dm2 dm3 dm4 dm5 dm6
  e1m1 e1m2 e1m3 e1m4 e1m5 e1m6 e1m7 e1m8
  e2m1 e2m2 e2m3 e2m4 e2m5 e2m6 e2m7
  e3m1 e3m2 e3m3 e3m4 e3m5 e3m6 e3m7
  e4m1 e4m2 e4m3 e4m4 e4m5 e4m6 e4m7 e4m8
  end start
)

BSP_URL="https://github.com/fzwoch/quake_map_source/raw/refs/heads/master/bsp"
LIT_URL="https://github.com/qw-ctf/lits/raw/refs/heads/main/jscolour/id1_gpl"
LOC_URL="https://assets.quake.world/maps"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

MAX_JOBS=8

process_map() {
  local map="$1"
  local work="${TMP_DIR}/${map}"
  mkdir -p "${work}/maps" "${work}/locs"

  # download bsp
  curl -fsSL -o "${work}/${map}.bsp" "${BSP_URL}/${map}.bsp"

  # download lit
  curl -fsSL -o "${work}/${map}.lit" "${LIT_URL}/${map}.lit"

  # download loc
  curl -fsSL -o "${work}/${map}.loc" "${LOC_URL}/${map}.loc"

  # create zip containing maps/<name>.lit and locs/<name>.loc
  cp "${work}/${map}.lit" "${work}/maps/${map}.lit"
  cp "${work}/${map}.loc" "${work}/locs/${map}.loc"
  (cd "$work" && zip -q "${map}.zip" "maps/${map}.lit" "locs/${map}.loc")

  # concat zip to end of bsp, then compress using pigz
  cat "${work}/${map}.bsp" "${work}/${map}.zip" \
    | pigz > "${map}.bsp.gz"

  echo "  -> ${map}.bsp.gz"
}

for map in "${MAPS[@]}"; do
  process_map "$map" &

  while (( $(jobs -r | wc -l) >= MAX_JOBS )); do
    wait -n
  done
done

wait
echo "done"
