#!/usr/bin/python3.8

from socket import *     # per aprire le socket
import threading         # per gestire richieste multiple
import time

maxRequests = 40  # consento la connessione di massimo 40 client alla volta
serverPort = 1415
BUFF_SIZE = 262144  # 256 KiB

connections = {}


def instauraTunnel(socket1, socket2):
    try:
        while data := socket1.recv(BUFF_SIZE):
            socket2.send(data)
    except Exception as e:
        try:
            socket1.shutdown(SHUT_RDWR)
            socket1.close()
        except:
            pass
        try:
            socket2.shutdown(SHUT_RDWR)
            socket2.close()
        except:
            pass


def gestisciRichiesta(connectionSocket, addr):
    sessKey = ''
    try:
        connectionSocket.settimeout(2.0)
        # leggo i primi 8 byte della richiesta, essi mi identificano la sessKey
        sessKey = connectionSocket.recv(8).decode()
        connectionSocket.settimeout(10.0)
        isValid = True
        if sessKey not in connections:
            connections[sessKey] = [connectionSocket]
        else:
            if (len(connections[sessKey]) == 1):
                connections[sessKey].append(connectionSocket)
            else:
                isValid = False  # sto provando ad aggiungere un altro peer, PROIBITO!

        connectionCompleted = False
        if isValid:
            for x in range(10):
                if len(connections[sessKey]) == 2:
                    connectionCompleted = True
                    break
                time.sleep(1)
        if not connectionCompleted:  # timeout raggiunto
            connectionSocket.shutdown(SHUT_RDWR)
            connectionSocket.close()
            del connections[sessKey]
        else:
            # connessione stabilita
            th = threading.Thread(target=instauraTunnel, args=(
                connections[sessKey][1], connections[sessKey][0]))
            th.start()
            instauraTunnel(connections[sessKey][0], connections[sessKey][1])
            th.join()
            connections[sessKey][0].shutdown(SHUT_RDWR)
            connections[sessKey][0].close()
            connections[sessKey][1].shutdown(SHUT_RDWR)
            connections[sessKey][1].close()
            del connections[sessKey]
    except Exception as e:
        # print(e)
        try:
            connections[sessKey][0].shutdown(SHUT_RDWR)
            connections[sessKey][0].close()
        except:
            pass
        try:
            connections[sessKey][1].shutdown(SHUT_RDWR)
            connections[sessKey][1].close()
        except:
            pass
        try:
            connectionSocket.shutdown(SHUT_RDWR)
            connectionSocket.close()
        except:
            pass


serverSocket = socket(AF_INET, SOCK_STREAM)
serverSocket.bind(('', serverPort))
serverSocket.listen(maxRequests)  # resto in ascolto
print('ShareApp tunnel server in ascolto sulla porta', serverPort)

while True:
    # stabilisce una connessione con il client
    connectionSocket, addr = serverSocket.accept()
    print('Richiesta da parte di', addr, 'accettata!')
    th = threading.Thread(target=gestisciRichiesta,
                          args=(connectionSocket, addr))
    th.start()
