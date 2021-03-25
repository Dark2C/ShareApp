<?php
    if($req['request'] === 'getReceiverPendingRequest'){
        $currUser = getRequestingUser($req);
        $stmt = $conn->prepare("SELECT sessKey, sender, username, fileName, fileSize FROM pendingShares JOIN users ON users.ID = sender WHERE receiver=? AND status=0 ORDER BY requestDate DESC LIMIT 1");
        $stmt->bind_param("i", $currUser['ID']);
        $stmt->execute();
        $result = $stmt->get_result();
        $result = $result->fetch_assoc();
        if(!is_null($result)) {
            die(json_encode([
                'status' => 'success',
                'sessKey' => $result['sessKey'],
                'sender' => $result['username'],
                'sender_ID' => $result['sender'],
                'fileName' => $result['fileName'],
                'fileSize' => $result['fileSize']
            ]));
        } else err('NO_PENDING_REQUESTS');
    }
    if($req['request'] === 'setReceiverConfirmation'){
        if(!(
            array_key_exists('sessKey', $req) &&
            array_key_exists('response', $req)))
        err('MALFORMED_REQUEST');

        if(!($req['response'] == 1 || $req['response'] == -1))
        err('MALFORMED_REQUEST');

        $stmt = $conn->prepare("UPDATE pendingShares SET status=? WHERE sessKey=? AND status=0");
        $stmt->bind_param("is", $req['response'], $req['sessKey']);
        $stmt->execute();
        die(json_encode([
            'status' => 'success'
        ]));
    }
?>