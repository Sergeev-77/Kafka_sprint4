import faust
import json
import sys


def print_cnsl(*mess):
    print(*mess, file=sys.__stdout__)


app = faust.App(
    "message-reader-app",
    broker="localhost:9094, localhost:9095, kafka://localhost:9096",
)

orders_tpc = app.topic("customers.public.orders")
users_tpc = app.topic("customers.public.users")


@app.agent(orders_tpc)
async def orders(stream):
    async for message in stream:
        print_cnsl("order: ", message["payload"])


@app.agent(users_tpc)
async def users(messages):
    async for message in messages:
        print_cnsl("user: ", message["payload"])
