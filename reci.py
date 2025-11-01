import requests

# Pay to shopkeeper
url = "http://192.168.137.1:5000/pay"
data = {'username': 'dharmendresh', 'amount':100}
response = requests.post(url, json=data)
print(response.status_code)
print(response.text)

''''
# Recieving Request
url = "http://192.168.43.154:5000/untransact"
data = {'payee': 'dhar'}
response = requests.post(url, json=data)
print(response.status_code)
print(response.text)


# Pay to friend
url = "http://192.168.43.154:5000/transact"
data = {'from': 'pavan', 'to':'doddi', 'amount':40}
response = requests.post(url, json=data)
print(response.status_code)
print(response.text)



# Getting shop name
url = "http://192.168.43.154:5000/merchantname"
response = requests.get(url)
print(response.status_code)
print(response.text)
'''