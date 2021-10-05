from clickhouse_driver import Client

subs = [
    ("127.0.0.1", "9001"),
    ("127.0.0.1", "9002"),
    ("127.0.0.1", "9003"),
    ("127.0.0.1", "9004")
]
master = ("127.0.0.1", "9000")

def print_data(data):
    for row in data:
        print("Timestamp", row[0], sep=": ")
        print("Parameter", row[1], sep=": ")
        print("Value", row[2], sep=": ")
        print()

if __name__ == "__main__":
    for sub in subs:
        client = Client(sub[0], port=sub[1])

        # data = client.execute("SELECT * FROM db.entries")
        data = client.execute("SELECT * FROM billing.transactions")
        print("SUB port:", sub[1])
        print_data(data)
    
    client = Client(master[0], port=master[1])

    # data = client.execute("SELECT * FROM db.entries")
    data = client.execute("SELECT * FROM billing.transactions")
    print("MASTER port:", master[1])
    print_data(data)
