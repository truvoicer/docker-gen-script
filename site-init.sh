#!/bin/bash
ROOT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
WP_DIR_PATH="$ROOT_PATH/wordpress"
WP_PLUGINS_DIR_PATH="$WP_DIR_PATH/plugins"
SCRIPTS_DIR_PATH="$ROOT_PATH/scripts"
BUILDS_DIR_PATH="$ROOT_PATH/builds"
BUILD_PREFIX="ubuntu-2004-apache-mysql-php"
SITES_DIR="/Users/michaeltoriola/Projects/sites"
DB_DIR="$ROOT_PATH/databases"
MYSQL_LIB_DIR="/var/lib/mysql"

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
  [NETWORK]=${NETWORK:-sites_db}
  [DB_HOST]=${DB_HOST:-sites_db}
  [DB_USER]=${DB_USER:-root}
  [DB_ROOT_PASSWORD]=${DB_ROOT_PASSWORD:-password}
  [DB_PASSWORD]=${DB_PASSWORD:-password}
  [DB_CONTAINER]=${DB_CONTAINER:-sites_db}
  [IMPORT_PLUGINS]=${IMPORT_PLUGINS:-false}
)

env_data=(
  [PHP_VERSION]=${PHP_VERSION:-7_4}
  [CREATE_DB]=${CREATE_DB:-true}
  [IMPORT_DB_PATH]=${IMPORT_DB_PATH:-false}
  [GIT]=${GIT:-false}
)

placeholder_files=(
  "docker-compose.yml"
  ".env"
)


function buildPluginMappings {
  plugin_dirs=$(find $WP_PLUGINS_DIR_PATH -maxdepth 1 -type d)
  echo "$plugin_dirs"
}

function findReplaceForMac {
  query="<$1>"
  replace="$2"
  path="$3"

  if [ "${site_data[IMPORT_PLUGINS]}" == false ]; then
    return
  else
    # replace=$(buildPluginMappings)
    buildPluginMappings
  fi
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
  machine=$( sh "$SCRIPTS_DIR_PATH/get-os.sh" )
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

function executeDbImport {
  if [[ "${env_data[IMPORT_DB_PATH]}" == false ]]; then
    echo "--IMPORT_DB_PATH not found"
    echo "Skipping..."
    exit
  elif [[ ! -f "${env_data[IMPORT_DB_PATH]}" ]]; then
    echo "--IMPORT_DB_PATH file not found"
    echo "Skipping..."
    exit
  fi
  dbName="$1"
  requested_db_dir="$DB_DIR/${site_data[DB_HOST]}/mysql"
  filename=$(basename -- "${env_data[IMPORT_DB_PATH]}")

  if [[ ! -d "$requested_db_dir" ]]; then
    echo "Requested DB dir not found"
    echo "Requested DB dir: $requested_db_dir"
    echo "Skipping..."
    exit
  fi
  if [[ -z "$filename" ]]; then
    echo "Error extracting filename from path"
    echo "Filename: $filename"
    echo "Skipping..."
    exit
  fi

  dockerSql="$MYSQL_LIB_DIR/$filename"
  dockerSqlLocalPath="$requested_db_dir/$filename"

  cp "${env_data[IMPORT_DB_PATH]}" "$requested_db_dir"

  if [[ ! -f "$dockerSqlLocalPath" ]]; then
    echo "SQL copy failed: $dockerSqlLocalPath"
    echo "Skipping..."
    exit
  fi
  docker exec "${site_data[DB_CONTAINER]}" mysql -u "${site_data[DB_USER]}" -p"${site_data[DB_PASSWORD]}" --database "$dbName" -e "use $dbName; source $dockerSql;"
  rm $dockerSqlLocalPath
  if [[ -f "$dockerSqlLocalPath" ]]; then
    echo "SQL deletion failed: $dockerSqlLocalPath"
    exit
  fi
}

function executeDbCreate {
  dbName="$1"
  docker exec "${site_data[DB_CONTAINER]}" mysql -u "${site_data[DB_USER]}" -p"${site_data[DB_PASSWORD]}" -e "create database $dbName"
}

function createDatabase {
  dbName="$1"
  requested_db_dir="$DB_DIR/${site_data[DB_HOST]}"
  echo "Creating database: $dbName"
  if [ ! -d "$requested_db_dir" ]; then
    echo "DB host ${site_data[DB_HOST]} does not exist in databases directory"
    return
  fi
  if [ ! -d "$requested_db_dir/mysql/$dbName" ]; then
    executeDbCreate "$dbName"
    return
  fi
  echo "DB: $dbName already exists in DB ${site_data[DB_HOST]}"
  echo "Do you want to create another database? [y|n]"
  read createNewDbQuestion

  if [ "$createNewDbQuestion" == "y" ]; then
    echo "Enter a new DB name:"
    read dbName
    executeDbCreate "$dbName"
  fi
}

function cloneGitRepo {
  gitRepoUri="$1"
  site_dir="$2"
  git clone "$gitRepoUri" "$site_dir/html"
}

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

while [ $# -gt 0 ]; do
  param="${1/--/}"
  if [[ $1 == *"--"* ]]; then
    declare $param="$2"
    if array_key_exists $param in site_data; then
      site_data[$param]="$2"
    fi
    if ! array_key_exists $param in site_data; then
      env_data[$param]="$2"
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
echo "Using _path: $build_path"
if [[ ! -d "$build_path" ]]; then
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

createDatabase "${site_data[DB_NAME]}"

if [ "${env_data[GIT]}" == false ]; then
  echo "Finished..."
  exit
fi

cloneGitRepo "${env_data[GIT]}" "$site_dir"

executeDbImport "${site_data[DB_NAME]}"

echo "Finished..."
exit