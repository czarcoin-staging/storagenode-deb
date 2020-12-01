service postgresql start
go install storj.io/gateway
until pg_isready; do sleep 3; done
psql -U postgres -c 'create database teststorj4;'
export STORJ_SIM_POSTGRES=postgres://postgres@localhost/teststorj4?sslmode=disable
echo "STORJ_SIM DESTROY NETWORK"
storj-sim -x network destroy


echo "STORJ_SIM SETUP NETWORK"

# setup the network
storj-sim -x  --host 0.0.0.0 --satellites 1 network --dev --postgres=$STORJ_SIM_POSTGRES setup
sed -i 's/# metainfo.rate-limiter.enabled: true/metainfo.rate-limiter.enabled: false/g' $(storj-sim network env SATELLITE_0_DIR)/config.yaml

echo "STORJ_SIM RUN NETWORK"
storj-sim -x --host 0.0.0.0 --satellites 1 network --dev run
