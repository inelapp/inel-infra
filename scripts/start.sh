echo 'starting up...'

cd "$(dirname "$0")/.."

echo 'down services...'
docker-compose down

echo 'up services...'
docker-compose up -d

echo "Waiting for MongoDB service to be healthy..."
until [ "$(docker inspect --format='{{json .State.Health.Status}}' shopimax-dbv2)" == "\"healthy\"" ]; do
  sleep 2
done

echo "Configuring MongoDB replica set..."
docker exec shopimax-dbv2 mongosh --quiet --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo:27017" }
  ]
});
'

echo "Reconfiguring MongoDB replica set to fix host..."
docker exec shopimax-dbv2 mongosh --quiet --eval '
cfg = rs.conf();
cfg.members[0].host = "mongo:27017";
rs.reconfig(cfg, { force: true });
'

echo "Replica set configured successfully."
echo "Starting up services..."

docker-compose restart