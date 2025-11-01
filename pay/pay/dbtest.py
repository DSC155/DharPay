from tinydb import TinyDB, Query
import random as r
import os

os.remove("history_db.json")

db = TinyDB("history_db.json")

names = [
    "Aarav", "Maya", "Ethan", "Lila", "Noah",
    "Isha", "Leo", "Sofia", "Karan", "Ella",
    "Ravi", "Zara", "Owen", "Priya", "Lucas",
    "Nina", "Aditya", "Chloe", "Vikram", "Isla",
    "Ryan", "Anaya", "Sam", "Meera", "Daniel"
]

for x in range(20):
	template={
			"transaction_time": f"{1761219343+r.randint(-10000,10000)}",
			"username": f"{r.choice(names)}{r.randint(111,999)}",
			"amount": r.randint(5,500),
			"action": r.choice(["credit", "debit"]),
			"ip_add": f"192.168.1.{r.randint(0,50)}"
			}
	db.insert(template)

User = Query()
# result = db.search(User.amount > 25)
result = db.all()
print(result)

