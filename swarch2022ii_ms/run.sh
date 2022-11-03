docker build -t swarch2022ii_ms .

docker run -p 4000:4000 -e DB_HOST=172.17.0.1 -e DB_PORT=3306 -e DB_USER=swarch2022ii -e DB_PASSWORD=2022 -e DB_NAME=swarch2022ii_db -e URL=0.0.0.0:4000 swarch2022ii_ms

