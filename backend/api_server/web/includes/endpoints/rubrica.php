<?php
    if($req['request'] === 'listContacts'){
        $currUser = getRequestingUser($req);
        
        $stmt = $conn->prepare("SELECT users.ID, users.username, users.lastSeen, users.avatar FROM users JOIN rubrica ON users.ID = rubrica.user_B WHERE rubrica.user_A=?");
        $stmt->bind_param("i", $currUser['ID']);
        $stmt->execute();
        $result = $stmt->get_result();
        
        die(json_encode([
            'status' => 'success',
            'contacts' => $result->fetch_all(MYSQLI_ASSOC)
        ]));
    }

    if($req['request'] === 'addContact'){
        if(!array_key_exists('username', $req)) err('MALFORMED_REQUEST');
        $currUser = getRequestingUser($req);

        if(strtolower($currUser['username']) == strtolower($req['username'])) err('MALFORMED_REQUEST');

        $stmt = $conn->prepare("SELECT ID FROM users WHERE LOWER(username)=LOWER(?) LIMIT 1");
        $stmt->bind_param("s", $req['username']);
        $stmt->execute();
        $result = $stmt->get_result();
        $result = $result->fetch_assoc();
        if(is_null($result)) err('USER_NOT_FOUND');
        $req['user_ID'] = $result['ID'];

        $stmt = $conn->prepare("SELECT COUNT(*) AS connected FROM rubrica WHERE user_A=? AND user_B=? LIMIT 1");
        $stmt->bind_param("ii", $currUser['ID'], $result['ID']);
        $stmt->execute();
        $result = $stmt->get_result();
        $result = $result->fetch_assoc();
        if($result['connected'] > 0) err('USERS_ALREADY_CONNECTED');

        $stmt = $conn->prepare("INSERT INTO rubrica (user_A, user_B) VALUES (?,?)");
        $stmt->bind_param("ii", $currUser['ID'], $req['user_ID']);
        $stmt->execute();
        die(json_encode([
            'status' => 'success'
        ]));
    }

    if($req['request'] === 'removeContact'){
        if(!array_key_exists('user_ID', $req)) err('MALFORMED_REQUEST');
        $currUser = getRequestingUser($req);

        $stmt = $conn->prepare("DELETE FROM rubrica WHERE user_A=? AND user_B=? LIMIT 1");
        $stmt->bind_param("ii", $currUser['ID'], $req['user_ID']);
        $stmt->execute();
        
        die(json_encode([
            'status' => 'success'
        ]));
    }
?>