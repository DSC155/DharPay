# serve.py

from flask import Flask, request, jsonify, render_template
import socket
import os
from datetime import datetime
import json
import time
from tinydb import TinyDB, Query

app = Flask(__name__)

@app.route('/')
def home():
	return "✅ Flask server is running!"


def fetch_history_and_bal():
	print("🔄 Fetching and updating history & balance data...")
	time.sleep(2)
	print("✅ Data update completed.")
	return True


@app.route('/history')
def history():
	paircode = request.args.get('password')
	#with open("pair.code") as f:
		#d = json.loads(f.read())
		##crct_code=str(d["pair_code"])
	if True:
		with TinyDB("history_db.json") as db:
			User = Query()
			history_data = db.all()
		# os.remove('history_data.json')
		balance=0
		records = []
		for record in history_data:
			try:
				ts = int(record.get("transaction_time", 0))
				record["readable_time"] = datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M:%S")
				if record["action"]=='credit':
					balance+=int(record["amount"])
				else:
					balance-=int(record["amount"])
			except Exception as e:
				record["readable_time"] = "Invalid time"
				print(f" Invalid time coz of {e} {type(e)}")
			records.append(record)
		return render_template("history.html", records=records, balance=balance)
	else:
		return render_template("denied.html")


@app.route('/refresh_data', methods=["POST"])
def refresh_data():
	success = fetch_history_and_bal()
	if success:
		return jsonify({"message": "Data updated successfully!"})
	else:
		return jsonify({"message": "Failed to update data."}), 500


@app.route('/merchantname', methods=['GET'])
def mername():
#with open("pair.code") as f:
		#d = json.loads(f.read())
		#mn=str(d["servername"])
	return jsonify({'merchant':mn})

@app.route('/ping', methods=['GET'])
def ping():
	ip_address = request.remote_addr
	return jsonify({"message": f"Ping from your ip:{ip_address}!"})

@app.route('/ai', methods=['POST'])
def voice():
	data2=request.get_json()
	if data2['action']=="credit":
		data={'transaction_time':int(time.time()), "ip_add":request.remote_addr, "username":data2["payee"], "amount":data2["amount"]}
		try:
			with TinyDB("history_db.json") as db:
				db.insert(data)
			status = f"Payment Successfull"
			code=200
		except Exception as e:
			status = f"Payment Unsuccessfull ERROR:{e}"
			code=500
		return jsonify({
			"processed": data,
			"status": status
		}), code
	elif data2['action']=="transfer":
		data={'transaction_time':int(time.time()), "ip_add":request.remote_addr, "amount":data2["amount"],
				'from':data2['payer'], 'to':data2['payee']}
		try:
			with TinyDB("transact_db.json") as db:
				db.insert(data)
			status = f"Payment Successfull"
			code=200
		except Exception as e:
			status = f"Payment Unsuccessfull ERROR:{e}"
			code=500
		return jsonify({
			"processed": data,
			"status": status
		}), code
	else:
		return jsonify({
			"status": "Money Not Sent. Invalid Action"
		}), 500

@app.route('/transact', methods=['POST'])
def trans():
	data = request.get_json()
	data['transaction_time'] = int(time.time())
	data["ip_add"] = request.remote_addr
	try:
		with TinyDB("transact_db.json") as db:
			db.insert(data)
		status = f"Payment Successfull"
		code=200
	except Exception as e:
		status = f"Payment Unsuccessfull ERROR:{e}"
		code=500
	return jsonify({
		"processed": data,
		"status": status
	}), code


@app.route('/untransact', methods=['POST'])
def untrans():
	data = request.get_json()
	data['transaction_time'] = int(time.time())
	data["ip_add"] = request.remote_addr
	money=0
	try:
		with TinyDB("transact_db.json") as db:
			result = db.search(Query().to == data['payee'])
			db.remove(Query().to == data['payee'])
		for rec in result:
			money+=rec['amount']
		if money>0:
			status = f"Withdrawal Successfull"
			code=200
		else:
			status = f"No record found"
			code=425
	except Exception as e:
		status = f"Withdrawal Unsuccessfull ERROR:{e}"
		code=500
	return jsonify({
		"processed": {'records':result, 'total': money},
		"status": status
	}), code


@app.route('/transactions')
def transactions():
	paircode = request.args.get('password')
	with open("pair.code") as f:
		d = json.loads(f.read())
		crct_code=str(d["pair_code"])
	if paircode==crct_code:
		with TinyDB("transact_db.json") as db:
			User = Query()
			history_data = db.all()
		balance=0
		records = []
		for record in history_data:
			try:
				ts = int(record.get("transaction_time", 0))
				record["readable_time"] = datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M:%S")
				balance+=int(record["amount"])
			except Exception as e:
				record["readable_time"] = "Invalid time"
				print(f" Invalid time coz of {e} {type(e)}")
			records.append(record)
		return render_template("transactions.html", records=records, uncamt=balance)
	else:
		return render_template("denied.html")

@app.route('/pay', methods=['POST'])
def credit():
	data = request.get_json()
	data['transaction_time'] = int(time.time())
	data["action"] = "credit"
	data["ip_add"] = request.remote_addr
	try:
		with TinyDB("history_db.json") as db:
			db.insert(data)
		status = f"Payment Successfull"
		code=200
	except Exception as e:
		status = f"Payment Unsuccessfull ERROR:{e}"
		code=500
	return jsonify({
		"processed": data,
		"status": status
	}), code


@app.route('/debit', methods=['POST'])
def debit():
	data = request.get_json()
	paircode = request.args.get('code')
	with open("pair.code") as f:
		d = json.loads(f.read())
		crct_code=str(d["pair_code"])
	if paircode==crct_code:
		data['transaction_time'] = int(time.time())
		data["action"] = "debit"
		data["ip_add"] = request.remote_addr
		try:
			with TinyDB("history_db.json") as db:
				db.insert(data)
			status = f"Payment Successfull"
			code=200
		except Exception as e:
			status = f"Payment Unsuccessfull ERROR:{e}"
			code=500
		return jsonify({
			"processed": {'transaction_time': data['transaction_time'], "ip_add": data['ip_add']},
			"status": status
		}), code
	else:
		print(paircode, crct_code, type(paircode), type(crct_code))
		return jsonify({
			"processed": {'transaction_time': str(int(time.time())), "ip_add": str(request.remote_addr)},
			"status": "Access Denied"
		}), 403


if __name__ == '__main__':
	ip_address = socket.gethostbyname(socket.gethostname())
	print(f"Server running on: http://{ip_address}:5000")
	app.run(host='0.0.0.0', port=5000, debug=True)
