# 1. Развертывание кластера

Кластера на 3 ноды развертывается / переразвертывается (со сбросом всех текуших состояний) командной

`$>source kafka.sh`

В кластере создаются:
 * таблицы БД users и orders
 * коннектор к БД io.debezium.connector.postgresql.PostgresConnector
 * начальные данные для таблиц users и orders

Настройки коннектора
```json
{
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
}
```

# 2. Генерация новых записей в таблицы БД users и orders

`$>source generator.sh`

Скрипт раз в 1 секунду будет добавлять запись в одну из таблиц БД


# 3. Запуск консьюмера

Запускаем в отдельном терминале

`$>faust -A reader worker -l error`

Записи из БД, пришедшие в соответствующие топики, будут вычитываться из топиков и выводиться в терминал

![](/reader.png)

# 4. Мониторинг

По адресу http://localhost:3000/d/kafka-connect-overview-0/kafka-connect-overview-0?orgId=1&from=now-5m&to=now в сервисе Grafana будут представлены метрики нагрузки на кластер

![](/grafana.png)