function message() {
    if [[ $1 == "error" ]]; then
        color='\033[0;31m'
    else
        color='\033[0;32m'
    fi
    echo -e "\n${color}$2\033[0m\n";
}

message "success" "Error"
