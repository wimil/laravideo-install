source ./helpers/variables.sh

# Validamos los argumentos
if [[ -z "$server_name" && -z "$install_type" ]]; then
    echo "Uso: sh install.sh install_type=(storage|encoder) server_name=example.com"
    exit
fi

if [[ "$install_type" != "encoder" || "$install_type" != "storage" ]]; then
    echo "El tipo de instalacion solo puede ser: encoder o storage"
    exit
fi
