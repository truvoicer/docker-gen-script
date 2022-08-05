#!/bin/bash
BUILDS_DIR_PATH="../builds"
BUILD_PREFIX="ubuntu-2004-apache-mysql-php"
SITES_DIR="/Users/michaeltoriola/Projects/sites"

#Declare site_data as associative array
declare -A env_data
declare -A site_data

#Set site_data array default values for arguments
site_data=(
  [SITE_NAME]=${SITE_NAME:-false}
  [DB_NAME]=${DB_NAME:-false}
  [WP_PREFIX]=${WP_PREFIX:-wp_}
  [WEB_ROOT]=${WEB_ROOT:-false}
  [HTTP_PORT]=${HTTP_PORT:-false}
  [HTTP_SSL_PORT]=${HTTP_SSL_PORT:-false}
  [NETWORK]=${NETWORK:-sites-db}
  [DB_HOST]=${DB_HOST:-sites-db}
  [DB_USER]=${DB_USER:-root}
  [DB_ROOT_PASSWORD]=${DB_ROOT_PASSWORD:-password}
  [DB_PASSWORD]=${DB_PASSWORD:-password}
  [DB_CONTAINER]=${DB_CONTAINER:-sites-db-sites-db-1}
)

env_data=(
  [PHP_VERSION]=${PHP_VERSION:-8}
  [CREATE_DB]=${CREATE_DB:-true}
)

placeholder_files=(
  "docker-compose.yml"
  ".env"
)

function escapeString {
  escapedString=$(echo "$1" | sed "s/\//\\\\\//g")
  echo "$escapedString"
}

function array_key_exists {
  #Checks if arguments are entered the correct way
  if [ "$2" != in ]; then
    echo "Incorrect usage."
    echo "Correct usage: exists {key} in {array}"
    return
  fi
  #if array[key] ($3) is set, return set
  #if array[key] ($3) is not set, return nothing
  eval '[ ${'"$3"'[$1]+set} ]'
}

function findReplaceForMac {
  query="<$1>"
  replace="$2"
  path="$3"
  sed -i '' -e "s/$query/$(escapeString $replace)/g" "$path"
}

function replacePlaceholdersForMac {
    site_dir="$1"
    for file in ${placeholder_files[@]}; do
      path="$site_dir/$file"
      for placeholder in ${!site_data[@]}; do
        findReplaceForMac "$placeholder" "${site_data[$placeholder]}" "$path"
      done
    done
}

function replacePlaceholders {
  site_dir="$1"
  machine=$( sh ./get-os.sh )
  if [ "$machine" = "Mac" ]; then
    replacePlaceholdersForMac "$site_dir"
  fi
}

function copyBuildDir {
  build_path="$1"
  site_dir="$2"
  cp -r "$build_path" "$site_dir"
}

function buildDir {
  build_path="$1"
  site_dir="$2"
    
  dir_count=$(find $SITES_DIR -type d -name ${site_data[SITE_NAME]} | wc -l | tr -d " ")
  index=$(($dir_count+1))
  if [[ -n $3 ]]; then
    index=$3
  fi
  new_dir="${site_dir}_copy_${index}"
  if [[ -d "$new_dir" ]]; then
    buildDir  "$build_path" "$site_dir" $(($index+1))
  else
    echo "Dir: $new_dir"
    copyBuildDir "$build_path" "$new_dir"
  fi
}

function createDatabase {
  echo "Creating database: ${site_data[DB_NAME]}"
  docker exec "${site_data[DB_CONTAINER]}" mysql -u "${site_data[DB_USER]}" -p"${site_data[DB_PASSWORD]}" -e "create database ${site_data[DB_NAME]}"
}

while [ $# -gt 0 ]; do
  param="${1/--/}"
  if [[ $1 == *"--"* ]]; then
    declare $param="$2"
    if array_key_exists $param in script_data; then
      env_data[$param]="$2"
    fi
    if ! array_key_exists $param in script_data; then
      site_data[$param]="$2"
    fi
  fi
  shift
done

if [ "${site_data[SITE_NAME]}" == false ]; then
  echo "Error, --SITE_NAME not set."
  exit
elif [ "${site_data[WEB_ROOT]}" == false ]; then
  echo "Error, --WEB_ROOT not set."
  exit
elif [ "${site_data[HTTP_PORT]}" == false ]; then
  echo "Error, --HTTP_PORT not set."
  exit
elif [ "${site_data[HTTP_SSL_PORT]}" == false ]; then
  echo "Error, --HTTP_SSL_PORT not set."
  exit
fi

if [[ ! -d "$SITES_DIR" ]]; then
  mkdir -P "$SITES_DIR"
fi

build_path="$BUILDS_DIR_PATH/$BUILD_PREFIX${env_data[PHP_VERSION]}"
echo "Using build: $BUILD_PREFIX${env_data[PHP_VERSION]}"
if [[ ! -d "$BUILDS_DIR_PATH/$BUILD_PREFIX${env_data[PHP_VERSION]}" ]]; then
  echo "Error, build with php version not found"
  exit
fi

site_dir="$SITES_DIR/${site_data[SITE_NAME]}"
if [[ -d "$site_dir" ]]; then
  echo "Dir already exists $site_dir"
  echo "Finding dir name..."
  buildDir  "$build_path" "$site_dir"
else 
  echo "Dir: $site_dir"
  copyBuildDir "$build_path" "$site_dir"
fi

replacePlaceholders "$site_dir"

if [ "${env_data[CREATE_DB]}" == false ]; then
  echo "Finished..."
  exit
fi

if [ "${site_data[DB_NAME]}" == false ]; then
  site_data[DB_NAME]="${site_data[SITE_NAME]}_db"
fi
createDatabase
echo "Finished..."
exit