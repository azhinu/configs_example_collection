#!/usr/bin/env bash
# shellcheck disable=SC2086,SC2046

# This script find partition in selected ClickHouse database that older than $timeold, and archive it.
# Script pipeline:
# 1. Check variables and permissions
# 2. Find partitions in $database that older than $timeold by using system.parts max_date or max_time column
# 3. Detach old partitions
# 4. Tar without compression detached partitions and save to $archivePath/$database/$tableName/$partition.tar
# 5. Remove detached partition directory
#
# Tar using without compression because ClickHouse store tables compressed with LZ4 or zstd.
# Recomend to use ClickHouse zstd compression for better result. Compression method can be set on TTL interval.
# e.g "ALTER TABLE <database>.<table> MODIFY TTL <date column> + INTERVAL 1 WEEK RECOMPRESS CODEC(ZSTD(17));" - This will produce 'zstd -l 17' compression for data older than 1 week.
# Tested with ClickHouse 21.12.2.

set -eo pipefail
## VARS
# Clickhouse client path
clickhouseClient='clickhouse-client'
# Working database
database='database'
# Output path to store archives
archivePath='/mnt/backup'
# How old data to archive. Can accept number end type. E.g 1 month / 40 days. Rounded to months.
timeold="$(date +"%Y-%m-%d" -d "-1 month")"
# Dry run
dryrun=true
# Verbose output
verbose=false

## Constants
RED='\033[1;31m'
GRN='\033[0;32m'
BLUE='\033[0;36m'
ORNG='\033[0;0;33m'
NC='\033[0m' # No Color

function parseArgs() {
  # Parse Flags
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
      -c|--client)
        clickhouseClient="$2"
        shift # past argument
        shift # past value
        ;;
      -d|--database)
        database="$2"
        shift # past argument
        shift # past value
        ;;
      -s|--datastore)
        datastorePath="$(realpath "$2")"
        shift # past argument
        shift # past value
        ;;
      -o|--output)
        archivePath="$(realpath "$2")"
        shift # past argument
        shift # past value
        ;;
      -t|--timeold)
        timeold="$(date +"%Y-%m-%d" -d "-$2")"
        shift # past argument
        shift # past value
        ;;
      -v|--verbose)
        verbose=true
        shift # past argument
        ;;
      --start)
        dryrun=false
        shift # past argument
        ;;
      -h|--help)
        echo -e ${BLUE}'ClickHouse cleaner. Detach and archives old partitions.
    Usage:
      '${GRN}$(dirname "$0")'/clickhouse_cleaner'${ORNG}' [Flags]

      '${GRN}'Flags:
      '${ORNG}'    |  --start               '${NC}' — Start script. Otherwise run dry-mode
      '${ORNG}'-c  |  --client              '${NC}' — Path to ClickHouse client           | Default: clickhouse-client
      '${ORNG}'-d  |  --database            '${NC}' — Working database                    | Default: pcs_logs
      '${ORNG}'-s  |  --datastore           '${NC}' — Datatase store directory            | Default: auto
      '${ORNG}'-o  |  --output              '${NC}' — Path to store archives.             | Default: /u01/clickhouse
      '${ORNG}'-t  |  --timeold '${GRN}' "1 month"  '${NC}' — How old data archive. Accept number and type. Rounded to 1 month | Default: 1 month
      '${ORNG}'-v  |  --verbose             '${NC}' — Detailed output
      '${ORNG}'-h  |  --help                '${NC}' — Show this message'
        exit 0
        ;;
      *)    # unknown option
        echo -e "${BLUE}Unknown flag ${RED}$key${NC}. ${BLUE}Use ${ORNG}--help${BLUE} to show help."
        exit 0
        ;;
    esac
  done
}
function initChecks() {
  #Try connect clickhouseClient and find $datastorePath
  if [[ $datastorePath == '' ]]; then
    datastorePath=$($clickhouseClient --query "SELECT data_path FROM system.databases WHERE name = '$database';")
    if [[ $datastorePath == '' ]]; then
      echo -e "${BLUE}Can't get datastore path. Check database name."
      exit 0
    fi
  else
    $clickhouseClient --query "exit;"
  fi

  if [[ ! -w $archivePath ]]; then
    echo -e "${BLUE}Archive directory ${ORNG}$archivePath is ${RED}not exist${BLUE} or ${RED}not writeble${BLUE}!"
    exit 0
  fi

  if [[ ! -r $datastorePath ]]; then
    echo -e "${BLUE}Data store directory ${ORNG}$datastorePath${BLUE} is ${RED}not readable${BLUE}!"
    exit 0
  fi

  if [[ $dryrun == 'true' ]]; then
    echo -e "${RED}Running in dry mode! No changes will processed."
  fi

  if [[ $verbose == 'true' ]]; then
    echo -e ${BLUE}'All checks has been passed.
    '${BLUE}'Execution flags:
    '${GRN}'clickhouseClient='${ORNG}$clickhouseClient'  ,'${BLUE}'|'${ORNG}' --client
    '${GRN}'database='${ORNG}$database'                  ,'${BLUE}'|'${ORNG}' --database
    '${GRN}'datastorePath='${ORNG}$datastorePath'        ,'${BLUE}'|'${ORNG}' none
    '${GRN}'archivePath='${ORNG}$archivePath'            ,'${BLUE}'|'${ORNG}' --output
    '${GRN}'timeold='${ORNG}$timeold${BLUE}' (Processed) ,|'${ORNG}' --timeold
    '${GRN}'dryrun='${ORNG}$dryrun'                      ,'${BLUE}'|'${ORNG}' --start
    '${GRN}'verbose='${ORNG}$verbose'                    ,'${BLUE}'|'${ORNG}' --verbose'${NC} | column -ts ","
  fi
}

## Main
parseArgs "$@"
initChecks
echo -e "\n${GRN}Archive old ClickHouse data script starts..${NC}\n"


#Get old partition lists:
partitionList=$($clickhouseClient --format=TabSeparatedRaw --query="SELECT partition, name, database, table FROM system.parts WHERE (max_date < '$timeold' and max_date > '0000-00-00' OR max_time < toStartOfDay(toDate('$timeold')) AND max_time > '0000-00-00 00:00:00') AND database = '$database' AND active;")


echo -e "${BLUE}This partitions will affected! \n${ORNG}Part\tName\t\tDatabase\tTable\n$partitionList${NC}\n"

# Detach partitions
while read -r partition name database table ; do
  {
    echo -e "${GRN}DETACH PARTITION ${ORNG}$partition${GRN} FROM${ORNG} $database.$table${NC}"
    if [[ $dryrun == 'false' && $partition != '' ]]; then
      $clickhouseClient --query="ALTER TABLE $database.$table DETACH PARTITION $partition;"
    fi
  }
done <<< "$partitionList"


## Tar and move partitions
# Find detached partitions
detachedList=$(find "$datastorePath" -path '**/detached/*' -prune || true)

if [[ $verbose == 'true' ]]; then
  echo -e "${BLUE}Detached data list:\n${ORNG}$detachedList${NC}\n"
fi
if [[ $detachedList == '' && $tablesList != '' ]]; then
  echo -e "${BLUE}Detached list is ${RED}empy${BLUE}, but some partitions has been ${RED}detached${BLUE}.\nCheck ClickHouse data store path. All detached partition will be moved on next run.${NC}\n"
  exit 0
fi


for partition in $detachedList; do
  # Get UUID from partition directory
  # Cut last 2 dirs
  tableName="${partition%/*/*}"
  # Get directory basename
  tableName="$($clickhouseClient -q "SELECT name FROM system.tables WHERE uuid = '${tableName##*/}';")"

  # Dry-run
  if [[ $dryrun == 'true' ]]; then
    # Simulate tar
    echo -e "${GRN}tar ${ORNG}-cf ${BLUE}$archivePath/$database/$tableName/${partition##*/}.tar  -C ${partition%/*} ${partition##*/}\n"
    # Check if partition dir is writeble
    if [[ ! -w $partition ]]; then
      echo -e "${ORNG}$partition ${RED}is not writeble or not exist!${NC}\n"
    else
      echo -e "${BLUE}$database/$tableName/${partition##*/}${GRN} has been compressed! Removing uncompressed files!\n\n${GRN}rm ${ORNG}-rf ${BLUE}$partition${NC}\n"
    fi
  else
    if [[ ! -w $archivePath/$database/$tableName ]]; then
          mkdir -p "$archivePath/$database/$tableName"
    fi
    tar --backup=numbered -cf "$archivePath/$database/$tableName/${partition##*/}.tar"  -C "${partition%/*}" "${partition##*/}"
    rm -rf "$partition"
    echo -e "${BLUE}$database/$tableName/${partition##*/}${GRN} has been compressed! Removing uncompressed files!\n\n${GRN}rm ${ORNG}-rf ${BLUE}$partition${NC}\n"
  fi
done

echo -e "${GRN}All data has been processed!\n"
