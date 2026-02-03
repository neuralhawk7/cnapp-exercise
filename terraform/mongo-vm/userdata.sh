#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl gnupg ca-certificates cron awscli

# --- MongoDB install (example: 4.2 repo for Debian 10) ---
curl -fsSL https://pgp.mongodb.com/server-4.2.asc | apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" > /etc/apt/sources.list.d/mongodb-org-4.2.list
apt-get update -y
apt-get install -y mongodb-org

systemctl enable mongod
systemctl start mongod

# Create admin user (before enabling auth)
mongosh --eval "db.getSiblingDB('admin').createUser({user: '${mongo_admin_user}', pwd: '${mongo_admin_pass}', roles:[{role:'root',db:'admin'}]})" || true

# Enable auth
sed -i 's/^#security:/security:/g' /etc/mongod.conf || true
grep -q '^security:' /etc/mongod.conf || echo 'security:' >> /etc/mongod.conf
grep -q 'authorization:' /etc/mongod.conf || echo '  authorization: enabled' >> /etc/mongod.conf

systemctl restart mongod

# Backup script
cat >/usr/local/bin/mongo_backup.sh <<'EOF'
#!/bin/bash
set -euxo pipefail
TS=$(date -u +%Y%m%dT%H%M%SZ)
DIR="/tmp/mongodump-$TS"
ARCHIVE="/tmp/mongodump-$TS.tgz"

mongodump --archive="$DIR.archive" --gzip --username "${mongo_admin_user}" --password "${mongo_admin_pass}" --authenticationDatabase admin
tar -czf "$ARCHIVE" -C /tmp "$(basename "$DIR.archive")" || true

aws s3 cp "$DIR.archive" "s3://${backup_bucket}/backups/mongodump-$TS.archive.gz" --acl public-read
EOF

chmod +x /usr/local/bin/mongo_backup.sh

# Nightly at 1:15am UTC
echo "15 1 * * * root /usr/local/bin/mongo_backup.sh" > /etc/cron.d/mongo_backup
systemctl restart cron || true