# Server Tunnel

Il server tunnel si occupa di instaurare una connessione tra due client, affinché il client Sender possa inviare dati al client Receiver.\
Il funzionamento è semplice, innanzitutto è necessario dire che virtualmente la comunicazione tra Sender e Receiver è a senso unico, gli unici pacchetti che il Receiver inoltra sono solo quelli necessari a instaurare la comunicazione; Per mettersi in comunicazione, i due attori condividono una chiave di 8 caratteri, la sessKey, che entrambi inoltrano al Server Tunnel: grazie a questa chiave il server sa che i due client sono "entangled";\
Subito dopo l'invio della chiave, viene spedito il carattere "S" o "R" rispettivamente da parte del Sender e del Receiver, poi il Sender comincerà ad inviare uno stream di dati, i quali saranno inoltrati al Receiver.\
Quando il Sender ha terminato l'invio dei dati, chiude la Socket e, allo stesso modo, il server chiude la socket con il Receiver.\
**That is!**

## Come compilo lo script?
É possibile compilare il codice sorgente in un eseguibile Standalone installando il package pyinstaller:
```
pip install pyinstaller
```

E dando, dalla directory contenente lo script, il comando:
```
pyinstaller --onefile shareapp_tunnel.py
```
