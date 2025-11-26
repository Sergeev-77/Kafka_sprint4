#!/bin/bash
set -e

echo "🚀 Пересоздание кластера Kafka.."

docker-compose down -v && docker-compose up -d

echo -e "\n⏳ Ожидаем запуск кластера (10 сек)\n"

sleep 10

echo "🔍 Проверяем доступность кластера..."

until docker exec kafka-0 /opt/bitnami/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server kafka-0:9092 > /dev/null 2>&1; do
    echo "⏳ Ожидаем готовность кластера..."
    sleep 5
done

until curl -s -f -o /dev/null http://localhost:8083/; do
  sleep 2
done

echo -e "🚀 Кластер готов!\n"

echo -e "\n🚀 Создаем таблицы в БД\n"

SQL_CREATE_TABLES="
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    product_name VARCHAR(100),
    quantity INT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
); 
"

docker exec -it postgres psql -h 127.0.0.1 -U postgres-user -d customers -c "$SQL_CREATE_TABLES"

echo -e "🚀 Таблицы в БД созданы! \n"

echo -e "\n🚀 Инициализируем коннектор io.debezium.connector.postgresql.PostgresConnector \n"

curl -s -X PUT -H "Content-Type: application/json" --data '{
   "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
   "database.hostname": "postgres",
   "database.port": "5432",
   "database.user": "postgres-user",
   "database.password": "postgres-pw",
   "database.dbname": "customers",
   "database.server.name": "customers",
   "table.include.list": "public.users, public.orders",
   "transforms": "unwrap",
   "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
   "transforms.unwrap.drop.tombstones": "false",
   "transforms.unwrap.delete.handling.mode": "rewrite",
   "topic.prefix": "customers",
   "topic.creation.enable": "true",
   "topic.creation.default.replication.factor": "-1",
   "topic.creation.default.partitions": "-1",
   "skipped.operations": "none"
}' http://localhost:8083/connectors/pg-connector/config | jq

echo -e "🚀 Коннектор создан \n"

echo -e "🚀 Добавляем строки в таблицы БД \n"

## Добавление пользователей
docker exec -it postgres psql -h 127.0.0.1 -U postgres-user -d customers -c "INSERT INTO users (name, email) VALUES ('John Doe', 'john@example.com');"
docker exec -it postgres psql -h 127.0.0.1 -U postgres-user -d customers -c "INSERT INTO users (name, email) VALUES ('Jane Smith', 'jane@example.com');"
docker exec -it postgres psql -h 127.0.0.1 -U postgres-user -d customers -c "INSERT INTO users (name, email) VALUES ('Alice Johnson', 'alice@example.com');"
docker exec -it postgres psql -h 127.0.0.1 -U postgres-user -d customers -c "INSERT INTO users (name, email) VALUES ('Bob Brown', 'bob@example.com');"


## Добавление заказов
docker exec -it postgres psql -h 127.0.0.1 -U postgres-user -d customers -c "INSERT INTO orders (user_id, product_name, quantity) VALUES (1, 'Product A', 2);"
docker exec -it postgres psql -h 127.0.0.1 -U postgres-user -d customers -c "INSERT INTO orders (user_id, product_name, quantity) VALUES (1, 'Product B', 1);"
docker exec -it postgres psql -h 127.0.0.1 -U postgres-user -d customers -c "INSERT INTO orders (user_id, product_name, quantity) VALUES (2, 'Product C', 5);"
docker exec -it postgres psql -h 127.0.0.1 -U postgres-user -d customers -c "INSERT INTO orders (user_id, product_name, quantity) VALUES (3, 'Product D', 3);"
docker exec -it postgres psql -h 127.0.0.1 -U postgres-user -d customers -c "INSERT INTO orders (user_id, product_name, quantity) VALUES (4, 'Product E', 4);"
