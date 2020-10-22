# laravideo-install Servers
script bash para instalar los servidores encoder y storage de laravideo

## Install encoder server

```bash
yum update -y
yum install git -y
git clone https://github.com/wimil/laravideo-install.git
cd laravideo-install
```

Asignar permisos al instalador
```bash
chmod +x install.sh
```

Iniciar la instalacion
```bash
./install.sh
```
