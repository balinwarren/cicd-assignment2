from flask import Flask, jsonify
import psycopg2
import random
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Database connection setup
def get_db_connection():
    conn = psycopg2.connect(
        dbname="motd_db", user="postgres", password="password", host="localhost"
    )
    return conn

@app.route('/motd', methods=['GET'])
def get_random_motd():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT message FROM motds')
    messages = cur.fetchall()
    cur.close()
    conn.close()
    
    # Pick a random message
    random_motd = random.choice(messages)[0]
    return jsonify({"motd": random_motd})

if __name__ == '__main__':
    app.run(debug=True)
