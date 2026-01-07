import json
import pymongo
import os
import time
from datetime import datetime
from urllib.parse import quote_plus

def lambda_handler(event, context):
    """
    Lambda que se conecta directamente a DocumentDB para escuchar change streams
    Se ejecuta cada minuto via CloudWatch Events
    """
    
    docdb_uri = os.environ['DOCDB_URI']
    
    try:
        client = pymongo.MongoClient(docdb_uri, 
                                   ssl=True,
                                   tlsCAFile='global-bundle.pem',
                                   retryWrites=False)
        
        db = client['demo_db']
        collection = db['users']
        
        # Configurar change stream pipeline
        pipeline = [
            {'$match': {'operationType': {'$in': ['insert', 'update', 'delete']}}}
        ]
        
        # Escuchar por tiempo limitado (4 minutos max)
        timeout_seconds = 240
        start_time = time.time()
        changes_processed = 0
        
        print("Starting change stream listener...")
        
        with collection.watch(pipeline, full_document='updateLookup') as stream:
            for change in stream:
                # Verificar timeout
                if time.time() - start_time > timeout_seconds:
                    print("Timeout reached, stopping stream")
                    break
                
                process_change(change)
                changes_processed += 1
                
                # Procesar máximo 100 cambios por ejecución
                if changes_processed >= 100:
                    print("Max changes processed, stopping")
                    break
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Processed {changes_processed} changes',
                'execution_time': time.time() - start_time
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
    
    finally:
        if 'client' in locals():
            client.close()

def process_change(change):
    """Procesa un cambio individual del stream"""
    
    operation = change['operationType']
    document_id = change['documentKey']['_id']
    
    print(f"Change detected: {operation} on document {document_id}")
    
    if operation == 'insert':
        document = change.get('fullDocument', {})
        print(f"New document: {json.dumps(document, default=str)}")
        
    elif operation == 'update':
        updated_fields = change.get('updateDescription', {}).get('updatedFields', {})
        print(f"Updated fields: {json.dumps(updated_fields, default=str)}")
        
    elif operation == 'delete':
        print(f"Document deleted: {document_id}")
    
    # Aquí agregar lógica de procesamiento:
    # - Enviar a SQS/SNS
    # - Actualizar otros sistemas
    # - Generar notificaciones