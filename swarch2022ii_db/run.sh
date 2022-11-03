docker build -t swarch2022ii_db .

docker run -d -t -i -p 3306:3306 --name swarch2022ii_db swarch2022ii_db

docker run --name db_client -d --link swarch2022ii_db:db -p 8081:80 phpmyadmin