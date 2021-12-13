#!/usr/bin/env bash
#
# @file  Autoaliases
# @brief Commande d'aide pour la manipulations de la CI et petits outils

set -o errexit
set -o pipefail
set -o nounset

var_directory='out'
html_directory="${var_directory}/html"
pdf_directory="${var_directory}/pdf"
md_directory="${var_directory}/markdown"
package_directory="${var_directory}/packages"
artefacts_directory="${var_directory}/artefacts"
templates_directory=.'./templates'
templates_html_directory=.'./templates/html'


# @description create color variables
#
# @noargs
#
init_colours() {
  local ncolors

  red=''
  yellow=''
  green=''
  reset=''
  cyan=''

  if ! test -t 1; then
    return
  fi

  if ! tput longname >/dev/null 2>&1; then
    return
  fi

  ncolors=$(tput colors)

  if ! test -n "${ncolors}" || test "${ncolors}" -le 7; then
    return
  fi

  red=$(tput setaf 1)
  green=$(tput setaf 2)
  yellow=$(tput setaf 3)
  cyan=$(tput setaf 6)
  reset=$(tput sgr0)

  declare -g red
  declare -g green
  declare -g yellow
  declare -g cyan
  declare -g reset
}

# Utiliy Fonctions
debug() {
  if [[ "${MY_DEBUG_MODE}" -eq "1" ]]; then
    printf 'DEBUG: %s\n' "$@" >&2
  fi
}

#
# @file  Title of file script
# @brief Small description of the script.

# @description display a message in error color
#
# @arg $1 string message to display
#
error() {
  if [[ -n $1 ]]; then
    printf '%s%s%s\n' "${red}" "${*}" "${reset}" 1>&2
  fi
}

# @description display a message in warning color
#
# @arg $1 string message to display
#
warning() {
  if [[ -n $1 ]]; then
    printf '%s%s%s\n' "${yellow}" "${*}" "${reset}" 1>&2
  fi
}

# @description display a message in info color
#
# @arg $1 string message to display
# @arg $2 int add a breakline after message = 1
#
info() {
  if [[ -n $1 ]]; then
    if [[ $2 -eq 1 ]]; then
      printf '%s%s%s\n' "${cyan}" "$1" "${reset}" 1>&2
    else
      printf '%s%s%s' "${cyan}" "$1" "${reset}" 1>&2
    fi
  fi
}

# @description display a message without color
#
# @arg $1 string message to display
# @arg $2 int add a breakline after message = 1
#
message() {
  if [[ -n $1 ]]; then
    if [[ $2 -eq 1 ]]; then
      printf '%s%s\n' "${reset}" "$1" 1>&2
    else
      printf '%s%s' "${reset}" "$1" 1>&2
    fi
  fi
}
# @description display a message in success color
#
# @arg $1 string message to display
#
success() {
  if [[ -n $1 ]]; then
    printf '%s%s%s\n' "${green}" "${*}" "${reset}" 1>&2
  fi
}

# @description exit script with error message and error code
#
# @arg $1 string Error message
# @arg $2 int Error code
#
# @exitcode >0
fail() {
  error "$1"
  finish $2
}

# @description exit script with error code
#
# @arg $1 int Error code
#
# @exitcode >0
finish() {
  if [[ $sourced -eq 1 ]]; then
    return $1
  else
    set +e
    set +E
    set +o pipefail
    exit $1
  fi
}

# -------------------------------------------------------------------------------- #
# Get Cron translation                                                             #
# -------------------------------------------------------------------------------- #
#  Call an Api to get human readable information about crontab config              #
# -------------------------------------------------------------------------------- #

get_cron_translation() {
  #new repository for that
  docker run --rm registry.gitlab.com/betd/public/docker/python-cron-describe "$1" "fr_FR"
}

# -------------------------------------------------------------------------------- #
# md to html                                                                       #
# -------------------------------------------------------------------------------- #
# Generate a html file from markdown file  using pandoc                            #
# -------------------------------------------------------------------------------- #

md_to_html() {
  docker run -v "$PWD":/build ntwrkguru/pandoc-gitlab-ci pandoc -s -c github-pandoc.css -c override.css -f markdown -t html5 "$1" -o "$2"
}

# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
merge_md() {
  info "- Merging markdown" 1
  (

    # shellcheck disable=SC2164
    cd "${md_directory}"
    rm -f report.markdown
    # shellcheck disable=SC2035
    # shellcheck disable=SC2012
    ls -1 *.md | sort -V | while read -r file; do
      \cat "${file}" >>report.markdown
    done
  )
  success "... OK"
}

# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
convert_md() {
  info "- fusion des markdown en html" 1
  md_to_html "${md_directory}/report.markdown" "${html_directory}/index.html"
  sed -i "/{PHPUNIT_REPORT}/{
r ${html_directory}/phpunit.html
d
}" "${html_directory}/index.html"
  success "... OK"
}

# -------------------------------------------------------------------------------- #
# download css                                                                     #
# -------------------------------------------------------------------------------- #
# Download github css file for pandocs html generation                             #
# -------------------------------------------------------------------------------- #

download_css() {
  info "- Downloading css" 1
  curl -sS -o "$html_directory/github-pandoc.css" https://gist.githubusercontent.com/dashed/6714393/raw/ae966d9d0806eb1e24462d88082a0264438adc50/github-pandoc.css
  success "... OK"
}

# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
start_gotenberg() {
  docker run --rm --name gotenberg -p 3000:3000 -d thecodingmachine/gotenberg:6 > /dev/null
}

# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
stop_gotenberg() {
  docker stop gotenberg > /dev/null
}

# -------------------------------------------------------------------------------- #
# download css                                                                     #
# -------------------------------------------------------------------------------- #
# Download github css file for pandocs html generation                             #
# -------------------------------------------------------------------------------- #

download_css() {
  info "- Downloading css" 1
  curl -sS -o "$html_directory/github-pandoc.css" https://gist.githubusercontent.com/dashed/6714393/raw/ae966d9d0806eb1e24462d88082a0264438adc50/github-pandoc.css
  success "... OK"
}

# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #

generate_pdf() {
    info "- Converting html to pdf" 1
  (
    # shellcheck disable=SC2164
    cp ${templates_html_directory}/* "$html_directory"
    cd "$html_directory"
    rm -f ../pdf/borderaux.pdf

    curl -sS --request POST \
      --url docker:3000/convert/html \
      --header 'Content-Type: multipart/form-data' \
      --form files=@index.html \
      --form files=@header.html \
      --form files=@github-pandoc.css \
      --form files=@override.css \
      --form marginTop=0.5 \
      --form marginBottom=0.5 \
      --form marginLeft=0 \
      --form marginRight=0 \
      -o ../pdf/borderaux.pdf
  )
  success "... OK"
}

# -------------------------------------------------------------------------------- #
# Generate phpunit report                                                          #
# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #

generate_phpunit_report() {
  rm "$html_directory/phpunit.html" || true
  # shellcheck disable=SC2002
  \cat "${artefacts_directory}/coverage/index.html" \
    | grep -zoE '<header>.*\/footer>.*<\/div>' \
    | perl -0777 -pe 's@<ol.*</ol>@<h2>Rapport des tests unitaires</h2>@gms' \
    | sed 's@<strong>Code Coverage</strong>@<strong>Couverture de code</strong>@g' \
    | sed 's@<strong>Lines</strong>@<strong>Lignes</strong>@g' \
    | sed 's@<strong>Functions and Methods</strong>@<strong>Fonctions and Méthodes</strong>@g' \
    | sed 's@<h4>Legend</h4>@<h4>Légende</h4>@g' \
     >"$html_directory/phpunit.html"

  \cat "${templates_directory}/40-phpunit.md"|envsubst > ${md_directory}/40-phpunit.md
}

# -------------------------------------------------------------------------------- #
# Generate sonarqube report                                                       #
# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #

generate_sonarqube_report() {
  local branch
  branch="$1"
  info "- Generation du rapport sonarqube " 1
  docker run --rm -e SONAR_HOST="${SONAR_HOST}" -e SONAR_PROJECT_KEY="${SONAR_PROJECT_KEY}" -e SONAR_LOGIN="${SONAR_LOGIN}" -v "$(pwd)":/project -w /project registry.gitlab.com/betd/public/docker/sonar-scanner-cli:4.6.2.2472 sh -c "sonar-cnes-report --disable-report  -n /opt/sonar-cnes-report/template/template.md -b $branch" #> /dev/null 2>&1
  docker run --rm -v "$(pwd)":/project -w /project registry.gitlab.com/betd/public/docker/sonar-scanner-cli:4.6.2.2472 sh -c "rm -fr conf"
  file=$(ls -1 ./*-analysis-report.md)
  sed -i -e 's/Criticit�/Criticité/g' "$file"
  mv --force "$file" "$md_directory/30-sonarqube.md"
  success "... OK"
}

# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
#                                                                                  #
# -------------------------------------------------------------------------------- #
init() {
  init_colours
  success "Génération du rapport"
  info "- Nettoyage anciens fichiers" 1
  rm -f "${md_directory}"/*.md
  rm -f "${md_directory}"/*.markdown
  rm -fr "./${package_directory}"
  mkdir -p "./${package_directory}"
  mkdir -p "./${html_directory}"
  mkdir -p "./${pdf_directory}"
  mkdir -p "./${md_directory}"
  mkdir -p "./${artefacts_directory}"
  mkdir -p "./${html_directory}"
  success "... OK"
}

# -------------------------------------------------------------------------------- #
# Generate global report                                                               #
# -------------------------------------------------------------------------------- #
#                                             #
# -------------------------------------------------------------------------------- #
generate_global_report() {
  branch=$1
  start_gotenberg
  download_css
  generate_phpunit_report
  generate_sonarqube_report "$branch"
  merge_md
  convert_md
  generate_pdf
  stop_gotenberg
}

main() {
  set -E
  init
  generate_sonarqube_report "$1"
  success "Generation complete"
}

main $@