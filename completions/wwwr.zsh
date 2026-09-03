#compdef wwwr bin/wwwr
# zsh completion for bin/wwwr. Install by adding the completions/ directory to
# fpath before compinit in ~/.zshrc:
#   fpath=(/path/to/wwworkremote/core/completions $fpath)
#   autoload -Uz compinit && compinit

_wwwr() {
  local -a commands
  commands=(
    'status:pipeline health summary'
    'postings:list postings matching filters'
    'transition:apply a lifecycle/pipeline event to a posting'
    'match:job-fit score and analysis for a posting'
    'interview-prep:print or generate an interview prep pack'
    'help:detailed help for a command'
  )

  _arguments -C \
    '1: :->cmd' \
    '*:: :->args'

  case $state in
    cmd)
      _describe -t commands 'wwwr command' commands
      _values 'flag' '--help' '-h'
      ;;
    args)
      case $words[1] in
        postings)
          _values -s ' ' 'filter' \
            '--company=' '--source-id=' '--role-family=' '--location=' '--remote' '--contract'
          ;;
        transition)
          if (( CURRENT == 3 )); then
            _values 'event' favorite apply interview offer reject ignore archive
          fi
          ;;
        match)
          _values 'flag' '--source=' '--escalate'
          ;;
        interview-prep)
          _values 'flag' '--regenerate' '--spoken' '--export' '--export='
          ;;
        help)
          _describe -t commands 'wwwr command' commands
          ;;
      esac
      ;;
  esac
}

_wwwr "$@"
