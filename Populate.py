import random
from faker import Faker
from datetime import datetime, timedelta

fake = Faker('en_IN')

# Configuration: Ensure 100+ rows per table as per TAE 2 rubric
NUM_BIKES = 150
NUM_MECHANICS = 100
NUM_PARTS = 120
NUM_SERVICES = 400

sql_file = "data.sql"

bikes = []
for _ in range(NUM_BIKES):
    chassis = f"RE-{fake.unique.random_int(min=10000, max=99999)}"
    reg = fake.unique.license_plate()
    model = random.choice(['Classic 350', 'Bullet 350', 'Interceptor 650', 'Himalayan 450', 'Meteor 350'])
    engine = random.choice(['350cc J-Series', '648cc Parallel Twin', '452cc Sherpa'])
    owner = fake.name()
    bikes.append((chassis, reg, model, engine, owner))

with open(sql_file, 'w') as f:
    f.write("USE GarageFleetDB;\n\n")

    # 1. Insert Motorcycles
    f.write("-- Insert 150+ Motorcycles\n")
    for b in bikes:
        f.write(f"INSERT INTO MOTORCYCLE VALUES ('{b[0]}', '{b[1]}', '{b[2]}', '{b[3]}', '{b[4]}');\n")

    # 2. Insert Mechanics
    f.write("\n-- Insert 100+ Mechanics\n")
    for i in range(1, NUM_MECHANICS + 1):
        name = fake.name()
        spec = random.choice(['General Service', 'Engine Rebuild', 'Electrical', 'Superbikes'])
        contact = fake.unique.numerify('9#########')
        f.write(f"INSERT INTO MECHANIC (Name, Specialization, ContactNo) VALUES ('{name}', '{spec}', '{contact}');\n")

    # 3. Insert Parts
    f.write("\n-- Insert 120+ Parts\n")
    for i in range(1, NUM_PARTS + 1):
        part = random.choice(['Oil Filter', 'Air Filter', 'Brake Pad', 'Spark Plug', 'Chain Lube', 'Engine Oil'])
        brand = random.choice(['Motul', 'Bosch', 'NGK', 'Brembo', 'RE Genuine'])
        grade = random.choice(['300V', '7100', 'Standard', 'Sintered'])
        stock = random.randint(20, 500)
        price = round(random.uniform(150.0, 3000.0), 2)
        f.write(
            f"INSERT INTO PARTS_INVENTORY (PartName, Brand, Grade, StockQuantity, UnitPrice) VALUES ('{part}', '{brand}', '{grade}', {stock}, {price});\n")

    # 4 & 5. Insert Services & Line Items
    f.write("\n-- Insert 400+ Services and Line Items\n")
    start_date = datetime(2025, 1, 1)

    for i in range(1, NUM_SERVICES + 1):
        chassis = random.choice(bikes)[0]
        mech_id = random.randint(1, NUM_MECHANICS)
        s_date = start_date + timedelta(days=random.randint(1, 300))
        odo = random.randint(5000, 60000)
        cost = round(random.uniform(1000.0, 15000.0), 2)

        f.write(
            f"INSERT INTO SERVICE_RECORD (ChassisNo, MechanicID, ServiceDate, OdometerReading, TotalCost) VALUES ('{chassis}', {mech_id}, '{s_date.strftime('%Y-%m-%d')}', {odo}, {cost});\n")

        # Insert 1 to 4 parts per service
        used_parts = random.sample(range(1, NUM_PARTS + 1), random.randint(1, 4))
        for p_id in used_parts:
            qty = random.randint(1, 3)
            f.write(f"INSERT INTO SERVICE_LINE_ITEM (ServiceID, PartID, QuantityUsed) VALUES ({i}, {p_id}, {qty});\n")

print(f"Success! {sql_file} generated. Import this file into MySQL.")