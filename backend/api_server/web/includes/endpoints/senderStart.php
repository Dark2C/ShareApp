<?php
    if($req['request'] === 'senderStart'){
        if(!(
            array_key_exists('receiver', $req) &&
            array_key_exists('fileName', $req) &&
            array_key_exists('fileSize', $req)))
        err('MALFORMED_REQUEST');

        $currUser = getRequestingUser($req);
        
        $stmt = $conn->prepare("SELECT COUNT(*) AS connected FROM rubrica WHERE user_A=? AND user_B=? LIMIT 1");
        $stmt->bind_param("ii", $req['receiver'], $currUser['ID']);
        $stmt->execute();
        $result = $stmt->get_result();
        $result = $result->fetch_assoc();

        if($result['connected'] > 0){
            $sessKey = getRandomString(8);
            $stmt = $conn->prepare("INSERT INTO pendingShares (sessKey, sender, receiver, fileName, fileSize) VALUES (?,?,?,?,?)");
            $stmt->bind_param("siisi", $sessKey, $currUser['ID'], $req['receiver'], $req['fileName'], $req['fileSize']);
            $stmt->execute();
            // gestione del timeout (polling su database solo lato server, trasparente al client)
            pollingCheck(function () {
                global $conn, $sessKey;
                // rimuovi i pendingShares in timeout
                $stmt = $conn->prepare("DELETE FROM pendingShares WHERE requestDate < (NOW() - INTERVAL 10 SECOND)");
                $stmt->execute();

                $stmt = $conn->prepare("SELECT COUNT(*) AS resolved FROM pendingShares WHERE sessKey=? AND status != 0 LIMIT 1");
                $stmt->bind_param("s", $sessKey);
                $stmt->execute();
                $result = $stmt->get_result();
                $result = $result->fetch_assoc();
                return $result['resolved'] > 0;
            }, function() {
                // user accepted or rejected the file... do something
                global $conn, $sessKey, $TUNNEL;
                $stmt = $conn->prepare("SELECT status FROM pendingShares WHERE sessKey=? LIMIT 1");
                $stmt->bind_param("s", $sessKey);
                $stmt->execute();
                $result = $stmt->get_result();
                $result = $result->fetch_assoc();
                $stmt = $conn->prepare("DELETE FROM pendingShares WHERE sessKey=? LIMIT 1");
                $stmt->bind_param("s", $sessKey);
                $stmt->execute();
                if($result['status'] == '1') {
                    // accepted
                    die(json_encode([
                        'status' => 'success',
                        'tunnelHost' => $TUNNEL['host'],
                        'tunnelPort' => $TUNNEL['port'],
                        'sessKey' => $sessKey
                    ]));
                } else err('REFUSED_BY_RECEIVER');
            }, function() { err('TIMEOUT_REACHED'); }, 30);

        } else err('USERS_NOT_CONNECTED');
    }
?>