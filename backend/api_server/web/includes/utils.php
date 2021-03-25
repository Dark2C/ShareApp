<?php
    function err($msg) {
        die(json_encode([
            'status' => 'error',
            'message' => $msg
        ]));
    }
    function getRandomString($len = 64) {
        return substr(base64_encode(random_bytes($len)), 0, $len);
    }
    function getRequestingUser($req) {
        global $conn;
        $stmt = $conn->prepare("SELECT ID, username, avatar FROM users WHERE authKey = ? LIMIT 1");
        $stmt->bind_param("s", $req['authentication']);
        $stmt->execute();
        $result = $stmt->get_result();
        $result = $result->fetch_assoc();
        if(is_null($result)) err('AUTH_ERROR');
        $stmt = $conn->prepare("UPDATE users SET lastSeen = CURRENT_TIMESTAMP() WHERE ID=?");
        $stmt->bind_param("i", $result['ID']);
        $stmt->execute();
        return $result;
    }

    function pollingCheck($condition, $callbackIfSuccess, $callbackIfTimeoutReached, $durationSeconds) {
        $done = false;
        for($i = 0; $i < $durationSeconds; $i++) {
            if($condition()) {
                $done = true;
                break;
            }
            sleep(1);
        }
        if($done) $callbackIfSuccess();
        else $callbackIfTimeoutReached();
    }
?>