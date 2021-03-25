#!/usr/bin/python3.8

from socket import *     # per aprire le socket
import threading         # per gestire richieste multiple
import time

maxRequests = 40 # consento la connessione di massimo 40 client alla volta
serverPort = 1415
BUFF_SIZE = 262144 # 256 KiB

connections = {}

def gestisciRichiesta(connectionSocket, addr):
    sessKey = ''
    try:
        connectionSocket.settimeout(2.0)
        # leggo i primi 8 byte della richiesta, essi mi identificano la sessKey
        sessKey = connectionSocket.recv(8).decode()
        # il 9o byte della richiesta identifica se sono il sender (S) o il receiver (R)
        peerType = connectionSocket.recv(1).decode()
        connectionSocket.settimeout(10.0)
        if peerType == 'S' or peerType == 'R':
            # la richiesta sembra valida
            isValid = True
            if sessKey not in connections:
                if peerType == 'S':
                    connections[sessKey] = {
                        'senderSocket': connectionSocket
                    }
                else:
                    connections[sessKey] = {
                        'receiverSocket': connectionSocket
                    }
            else:
                if peerType == 'S':
                    if ('senderSocket' not in connections[sessKey]):
                        connections[sessKey]['senderSocket'] = connectionSocket
                    else:
                        isValid = False # sto provando ad effettuare un replace del sender, PROIBITO!
                else:
                    if ('receiverSocket' not in connections[sessKey]):
                        connections[sessKey]['receiverSocket'] = connectionSocket
                    else:
                        isValid = False # sto provando ad effettuare un replace del sender, PROIBITO!
            
            connectionCompleted = False
            if isValid:
                for x in range(10):
                    if (peerType == 'S') and ('receiverSocket' in connections[sessKey]):
                        connectionCompleted = True
                        break
                    elif (peerType == 'R') and ('senderSocket' in connections[sessKey]):
                        connectionCompleted = True
                        break
                    time.sleep(1)
            if not connectionCompleted: # timeout raggiunto
                connectionSocket.shutdown(SHUT_RDWR)
                connectionSocket.close()
                del connections[sessKey]
            else:
                # connessione stabilita
                if peerType == 'S': # se sono il sender, mando i dati
                    while True:
                        data = connections[sessKey]['senderSocket'].recv(BUFF_SIZE)
                        if len(data) > 0:
                            connections[sessKey]['receiverSocket'].send(data)
                        else:
                            connections[sessKey]['senderSocket'].shutdown(SHUT_RDWR)
                            connections[sessKey]['senderSocket'].close()
                            connections[sessKey]['receiverSocket'].shutdown(SHUT_RDWR)
                            connections[sessKey]['receiverSocket'].close()
                            del connections[sessKey]
                            break
        else:
            # parametro non valido
                connectionSocket.shutdown(SHUT_RDWR)
                connectionSocket.close()
    except Exception as e:
        #print(e)
        try:
            connections[sessKey]['senderSocket'].shutdown(SHUT_RDWR)
            connections[sessKey]['senderSocket'].close()
        except:
            pass
        try:
            connections[sessKey]['receiverSocket'].shutdown(SHUT_RDWR)
            connections[sessKey]['receiverSocket'].close()
        except:
            pass
        try:
            connectionSocket.shutdown(SHUT_RDWR)
            connectionSocket.close()
        except:
            pass

serverSocket = socket(AF_INET,SOCK_STREAM)
serverSocket.bind(('',serverPort))
serverSocket.listen(maxRequests) # resto in ascolto
print('ShareApp tunnel server in ascolto sulla porta', serverPort)

while True:
    connectionSocket, addr = serverSocket.accept() #stabilisce una connessione con il client
    print('Richiesta da parte di', addr,'accettata!')
    th = threading.Thread(target=gestisciRichiesta, args=(connectionSocket, addr))
    th.start()
