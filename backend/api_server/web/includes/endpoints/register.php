<?php
    if($req['request'] === 'register'){
        if(is_array($req['authentication'])){
            $auth = $req['authentication'];
            // auth deve obbligatoriamente contenere un campo username ed una password
            if(!(array_key_exists('username', $auth) && array_key_exists('password', $auth)))
                err('MALFORMED_REQUEST');
            $auth['password'] = password_hash($auth['password'],  PASSWORD_DEFAULT);
            
            $stmt = $conn->prepare("SELECT ID FROM users WHERE username=? LIMIT 1");
            $stmt->bind_param("s", $auth['username']);
            $stmt->execute();
            $result = $stmt->get_result();
            $result = $result->fetch_assoc();
            if(!is_null($result)) err('USERNAME_TAKEN');

            // crea l'utente
            $authKey = getRandomString();
            $stmt = $conn->prepare("INSERT INTO users (username, password, authKey) VALUES (?,?,?)");
            $stmt->bind_param("sss", $auth['username'], $auth['password'], $authKey);
            $stmt->execute();
            die(json_encode([
                'status' => 'success',
                'authKey' => $authKey
            ]));
        } else err('MALFORMED_REQUEST');
    }
?>