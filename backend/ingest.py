# ingest.py
import os
import time
from langchain_community.document_loaders import DirectoryLoader, PyPDFLoader, TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_chroma import Chroma
from dotenv import load_dotenv
from langchain_huggingface import HuggingFaceEmbeddings

load_dotenv()

DATA_PATH = "data/"
CHROMA_DB_PATH = "chroma_db"

def create_vector_store():
    """
    Lê documentos de um diretório, os divide em pedaços (chunks),
    cria embeddings e os armazena em um banco de dados vetorial ChromaDB.
    """
    print("Iniciando a criação do Vector Store...")

 
    pdf_loader = DirectoryLoader(
        DATA_PATH,
        glob="**/*.pdf",
        loader_cls=PyPDFLoader,
        show_progress=True,
        use_multithreading=True
    )
    pdf_documents = pdf_loader.load()


    txt_loader = DirectoryLoader(
        DATA_PATH,
        glob="**/*.txt",
        loader_cls=TextLoader,
        loader_kwargs={'encoding': 'utf-8'}, 
        show_progress=True,
        use_multithreading=True
    )
    txt_documents = txt_loader.load()

    documents = pdf_documents + txt_documents
    print(f"Carregados {len(documents)} documentos.")

  
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
    chunks = text_splitter.split_documents(documents)
    print(f"Documentos divididos em {len(chunks)} chunks.")

    
    print("Inicializando modelo de embedding local (pode levar um tempo no primeiro uso)...")
    embedding_function = HuggingFaceEmbeddings(
        model_name="paraphrase-multilingual-MiniLM-L12-v2",
        model_kwargs={'device': 'cpu'} 
    )

   
    if os.path.exists(CHROMA_DB_PATH):
        print("Carregando Vector Store existente...")
        vector_store = Chroma(persist_directory=CHROMA_DB_PATH, embedding_function=embedding_function)
        
        
        existing_files = set()
        existing_items = vector_store.get()
        if existing_items and existing_items['metadatas']:
             for metadata in existing_items['metadatas']:
                existing_files.add(metadata.get('source'))
        
        print(f"Arquivos já processados: {len(existing_files)}")
        chunks_to_add = [chunk for chunk in chunks if chunk.metadata.get('source') not in existing_files]
        
        if not chunks_to_add:
            print("Nenhum documento novo para adicionar. Encerrando.")
            return
        
        print(f"Adicionando {len(chunks_to_add)} chunks de novos documentos...")
        chunks = chunks_to_add 
    else:
        print("Criando um novo Vector Store...")


    batch_size = 32 
    total_batches = (len(chunks) + batch_size - 1) // batch_size

    for i in range(0, len(chunks), batch_size):
        batch = chunks[i:i + batch_size]
        current_batch_num = (i // batch_size) + 1
        print(f"Processando lote {current_batch_num}/{total_batches}...")

        if i == 0 and not vector_store:
            vector_store = Chroma.from_documents(documents=batch, embedding=embedding_function, persist_directory=CHROMA_DB_PATH)
        else:
            vector_store.add_documents(batch)

       

    print(f"Vector Store criado com sucesso em '{CHROMA_DB_PATH}'!")

if __name__ == "__main__":
    create_vector_store()