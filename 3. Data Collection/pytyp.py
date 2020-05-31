import random
import names
import json
from faker import Faker

date = Faker()
random.seed(10)

total = 25
digits = "0123456789"

# CustomerID ie CID generation - PK
CID = []
for i in range(total + total):
    str = ""
    for j in range(4):
        if j == 0:
            str += random.choice(digits[1:])
        else:
            str += random.choice(digits)
    CID.append(str)
CID = random.sample(CID, total)

# Phone number generation - Unique
PhoneNo = []
for i in range(total + total):
    str = ""
    for j in range(10):
        if j == 0:
            str += random.choice(digits[7:])
        else:
            str += random.choice(digits[:])
    PhoneNo.append(str)
PhoneNo = random.sample(PhoneNo, total)

# First name and last name generation using 'names' module
FName = []
LName = []
for i in range(25):
    FName.append(names.get_first_name())
    LName.append(names.get_last_name())

# Address generation using downloaded json data set of 100 address from github
with open('address.json', 'r') as fp:
    addressJSON = json.load(fp)
dict = random.sample(addressJSON['addresses'], 25)
HouseNo = []
StreetAddress = []
City = []
State = []
Pincode = []
for i in dict:
    HouseNo.append(i['address1'].split(" ")[0])
    remx = i['address1'].split(" ")[0]
    StreetAddress.append(i['address1'].replace(remx + " ", ""))
    City.append(i['city'])
    State.append(i['state'])
    Pincode.append(i['postalCode'])

# Random gender irrespective of names
Gender = []
for i in range(total):
    Gender.append(random.choice(['M', 'm', 'W', 'w', 'O']))

with open('customerDATA.txt', 'w+') as fp:
    for i in range(total):
        fp.write("({} , '{}' , '{}' , '{}' , '{}' , '{}' , '{}' , '{}' , '{}' , '{}' , '{}' , {}),\n".
                 format(CID[i],
                        FName[i], LName[i], date.date_between(start_date='-30y', end_date='today', ), Gender[i],
                        (FName[i].lower()) + (LName[i].lower()) + "@wemail.com", PhoneNo[i], HouseNo[i],
                        StreetAddress[i], City[i], State[i], Pincode[i]))

with open('products.json', 'r') as fp:
    proJSON = json.load(fp)

CategoryTUPLE = list(set([(i[-1], i[-2]) for i in proJSON.values()]))
cateLen = len(CategoryTUPLE)

# Category ID generation - PK
CategoryID = []
for i in range(cateLen + cateLen):
    str = ""
    for j in range(4):
        if j == 0:
            str += random.choice(digits[1:])
        else:
            str += random.choice(digits)
    CategoryID.append(str)
CategoryID = random.sample(CategoryID, cateLen)

CategoryDICT = {}
for i in range(cateLen):
    CategoryDICT[(CategoryTUPLE[i])] = CategoryID[i]

with open('categoryDATA.txt', 'w') as fp:
    for i in CategoryDICT.keys():
        fp.write("({}, '{}', '{}'), \n".format(CategoryDICT[i].replace("'", r"\'"), i[1][:1], i[0].replace("'", r"\'")))

# Product ID generation - PK
ProductID = []
for i in range(len(proJSON.values()) * 2):
    str = ""
    for j in range(4):
        if j == 0:
            str += random.choice(digits[1:])
        else:
            str += random.choice(digits)
    ProductID.append(str)
ProductID = random.sample(ProductID, len(proJSON.values()))

with open('productDATA.txt', 'w+') as fp:
    j = 0
    for i in proJSON.values():
        fp.write("({} , '{}' , '{}' , '{}' , {} , {}, {}),\n".
                 format(ProductID[j], i[1].replace("'", r"\'"), i[0].replace("'", r"\'"), i[4].replace("'", r"\'"),
                        i[2], i[3], CategoryDICT[(i[-1], i[-2])]))
        j = j + 1

with open('productimagesourceDATA.txt', 'w+') as fp:
    j = 0
    for i in proJSON.values():
        li = i[5]
        for ii in li:
            fp.write("('{}' , {}),\n".
                     format(ii.replace("'", r"\'"), ProductID[j]))
        j = j + 1

SellerName = ['Appario Retail', 'Cloudtail', 'STPL', 'Electrama', 'Darshita', 'BasicDeal', 'weguarantee']
sellerLen = len(SellerName)

LocationSeller = []
for i in addressJSON['addresses']:
    LocationSeller.append(i['state'])
LocationSeller = random.sample(list(set(LocationSeller)), sellerLen)

# Seller ID generation - PK
SellerID = []
for i in range(sellerLen * 2):
    str = ""
    for j in range(4):
        if j == 0:
            str += random.choice(digits[1:])
        else:
            str += random.choice(digits)
    SellerID.append(str)
SellerID = random.sample(SellerID, sellerLen)

with open('sellerDATA.txt', 'w+') as fp:
    for j in range(sellerLen):
        fp.write("({}, '{}' , '{}'),\n".
                 format(SellerID[j], SellerName[j], LocationSeller[j]))

# Cart ID generation - PK
cartID = []
for i in range(total + total):
    str = ""
    for j in range(4):
        if j == 0:
            str += random.choice(digits[1:])
        else:
            str += random.choice(digits)
    cartID.append(str)
cartID = random.sample(cartID, total)

with open('cartDATA.txt', 'w+') as fp:
    for j in range(10):
        fp.write("({}, 0, 0,{}),\n".
                 format(cartID[j], random.choice(CID)))

ProductSizeDICT = {}
for i in range(len(ProductID)):
    ProductSizeDICT[int(ProductID[i])] = list(proJSON.values())[i][6]


with open('SellRelationDATA.txt', 'w+') as fp:
    lis = []
    for j in range(100 * 2):
        p = int(random.choice(ProductID))
        x = random.choice(SellerID[:sellerLen])
        lis.append((p, x))
    lis = list(set(lis))
    lis = random.sample(lis, 20)
    for i in lis:
        fp.write("({}, {}, '{}' ,{}),\n".
                 format(i[1], i[0], random.choice(ProductSizeDICT[p]), random.choice(range(5, 50))))


with open('CPRelationDATA.txt', 'w+') as fp:
    lis = []
    for j in range(100 * 2):
        p = int(random.choice(cartID[:10]))
        x = random.choice(ProductID[:10])
        lis.append((p, x))
    lis = list(set(lis))
    lis = random.sample(lis, 20)
    for i in lis:
        fp.write("({}, {}),\n".
                 format(i[1], i[0]))
        

# Transaction ID generation - PK
TransactionID = []
for i in range(300):
    str = ""
    for j in range(4):
        if j == 0:
            str += random.choice(digits[1:])
        else:
            str += random.choice(digits)
    TransactionID.append(str)
TransactionID = random.sample(TransactionID, 100)

# Order ID generation - PK
OrderID = []
for i in range(300):
    str = ""
    for j in range(4):
        if j == 0:
            str += random.choice(digits[1:])
        else:
            str += random.choice(digits)
    OrderID.append(str)
OrderID = random.sample(OrderID, 100)

print(OrderID)
with open('TransactionDATA.txt', 'w+') as fp:
    lisss=[]
    for i in range(100):
        a = TransactionID[i]
        b = OrderID[i]
        lisss.append((a, b))
    lisss = list(set(lisss))
    lisss = random.sample(lisss, 10)
    for i in range(10):
        fp.write("({}, {} , {}),\n".
                 format(a, random.choice([0, 1]), b))


with open('orderDATA.txt', 'w+') as fp:
    lisss=[]
    for i in range(10):
        a = random.choice(OrderID)
        b = random.choice(CID)
        c = cartID[i]
        lisss.append((a, b, c))
    lisss = list(set(lisss))
    lisss = random.sample(lisss, 8)
    for i in lisss:
        fp.write("({}, {} , {}, {}),\n".
                 format(i[0], random.choice([0, 1]), i[1], i[2]))
