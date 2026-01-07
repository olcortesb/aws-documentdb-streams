import json
import pymongo
import os
from datetime import datetime

def lambda_handler(event, context):
    docdb_uri = os.environ['DOCDB_URI']
    client = None
    
    try:
        print(f"Connecting to DocumentDB...")
        
        # Conectar a DocumentDB con timeouts agresivos
        client = pymongo.MongoClient(
            docdb_uri,
            ssl=True,
            tlsCAFile='global-bundle.pem',
            retryWrites=False,
            connectTimeoutMS=5000,  # 5 segundos
            serverSelectionTimeoutMS=5000,  # 5 segundos
            socketTimeoutMS=10000,  # 10 segundos
            maxPoolSize=1,  # Conexión única
            waitQueueTimeoutMS=2000  # 2 segundos
        )
        
        # Verificar conexión rápidamente
        client.admin.command('ping')
        print("Connected successfully")
        
        db = client['demo_db']
        collection = db['users']
        
        # Habilitar change streams si no están habilitados
        try:
            client.admin.command("modifyChangeStreams", database="demo_db", collection="users", enable=True)
            print("Change streams enabled for collection")
        except Exception as e:
            print(f"Change streams already enabled or error: {e}")
        
        # Parsear body si viene de API Gateway
        if isinstance(event, dict) and 'body' in event:
            if event['body']:
                event = json.loads(event['body'])
            else:
                event = {}
        
        # Crear documento
        document = {
            'user_id': event.get('user_id', 'user_123'),
            'name': event.get('name', 'John Doe'),
            'email': event.get('email', 'john@example.com'),
            'timestamp': datetime.utcnow(),
            'action': 'user_created'
        }
        
        print(f"Inserting document: {document}")
        
        # Insertar documento
        result = collection.insert_one(document)
        
        print(f"Document inserted with ID: {result.inserted_id}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Document inserted successfully',
                'document_id': str(result.inserted_id)
            })
        }
        
    except Exception as e:
        error_msg = str(e)
        print(f"Error: {error_msg}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': error_msg
            })
        }
    
    finally:
        if client:
            try:
                client.close()
            except:
                pass