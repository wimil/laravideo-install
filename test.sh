server_root=/var/www/test

sed -i "s/Subsystem      sftp/#Subsystem      sftp/g" ./utils/sshd_config
cat <<EOF >> ./utils/sshd_config


Subsystem sftp internal-sftp

Match User encoder
ForceCommand internal-sftp
PasswordAuthentication yes
ChrootDirectory $server_root
PermitTunnel no
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
EOF