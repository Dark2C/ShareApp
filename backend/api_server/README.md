# API Server

L'API Server consente la gestione delle utenze del servizio ed il coordinamento tra gli users affinché possa avvenire lo scambio di dati tramite il server di tunnel.

## Come configuro il servizio?
Per prima cosa è necessario un web server con supporto a PHP e MySQL, a tale scopo è possibile utilizzare XAMPP.\
Una volta installato un webserver ed il server MySQL, sarà sufficiente copiare il contenuto della cartella "web" nella root del webserver, importare lo schema del database ("*shareapp.sql*") e modificare il file "index.php" affinché punti correttamente al database.
