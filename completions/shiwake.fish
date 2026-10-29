complete -c shiwake -f
complete -c shiwake -n __fish_use_subcommand -a doctor -d 'check the tools shiwake needs'
complete -c shiwake -n __fish_use_subcommand -a version -d 'print the version'
complete -c shiwake -n __fish_use_subcommand -a help -d 'print usage'
complete -c shiwake -a '(__fish_complete_directories)'

complete -c shiwake -l dry-run -d 'list every move and change nothing'
complete -c shiwake -l json -d 'print the result as one JSON object, for scripts'
