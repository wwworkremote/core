# bash completion for bin/wwwr -- source this from ~/.bashrc:
#   source /path/to/wwworkremote/core/completions/wwwr.bash
# Works for the command whether invoked as `wwwr` or `bin/wwwr`.

_wwwr() {
  local cur prev words cword
  _init_completion 2>/dev/null || {
    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD
  }

  local commands="status postings transition match interview-prep help"

  # first argument: the subcommand
  if [[ $cword -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$commands --help -h" -- "$cur"))
    return
  fi

  local sub=${words[1]}
  case $sub in
    postings)
      COMPREPLY=($(compgen -W "--company= --source-id= --role-family= --location= --remote --contract" -- "$cur"))
      ;;
    transition)
      # words[2] is the id; words[3] is the event
      [[ $cword -eq 3 ]] && COMPREPLY=($(compgen -W "favorite apply interview offer reject ignore archive" -- "$cur"))
      ;;
    match)
      COMPREPLY=($(compgen -W "--source= --escalate" -- "$cur"))
      ;;
    interview-prep)
      COMPREPLY=($(compgen -W "--regenerate --spoken --export --export=" -- "$cur"))
      ;;
    help)
      [[ $cword -eq 2 ]] && COMPREPLY=($(compgen -W "$commands" -- "$cur"))
      ;;
  esac
}

complete -F _wwwr wwwr
complete -F _wwwr bin/wwwr
