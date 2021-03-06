<?php
    if($req['request'] === 'login'){
        if(is_array($req['authentication'])){
            $auth = $req['authentication'];
            // auth deve obbligatoriamente contenere un campo username ed una password
            if(!(array_key_exists('username', $auth) && array_key_exists('password', $auth)))
                err('MALFORMED_REQUEST');
            
            $stmt = $conn->prepare("SELECT ID, password, avatar FROM users WHERE username=? LIMIT 1");
            $stmt->bind_param("s", $auth['username']);
            $stmt->execute();
            $result = $stmt->get_result();
            $result = $result->fetch_assoc();
            if(is_null($result)) err('AUTH_ERROR');
            if(password_verify($auth['password'], $result['password'])) {
                $authKey = getRandomString();
                $stmt = $conn->prepare("UPDATE users SET authKey=? WHERE ID=?");
                $stmt->bind_param("si", $authKey, $result['ID']);
                $stmt->execute();
                die(json_encode([
                    'status' => 'success',
                    'authKey' => $authKey
                ]));
            } else err('AUTH_ERROR');
        } else err('MALFORMED_REQUEST');
    }
    if($req['request'] === 'getCurrentUser'){
        $currUser = getRequestingUser($req);
        die(json_encode([
            'status' => 'success',
            'user_ID' => $currUser['ID'],
            'username' => $currUser['username'],
            'avatar' => $currUser['avatar']
        ]));
    }
    if($req['request'] === 'syncFirebaseToken'){
        $currUser = getRequestingUser($req);
        $stmt = $conn->prepare("UPDATE users SET firebaseToken=? WHERE ID=?");
        $stmt->bind_param("si", $req['firebaseToken'], $currUser['ID']);
        $stmt->execute();
        die(json_encode([
            'status' => 'success'
        ]));
    }
?>