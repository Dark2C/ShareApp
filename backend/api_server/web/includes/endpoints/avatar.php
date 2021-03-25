<?php
    if($req['request'] === 'getAvatar'){
        $currUser = getRequestingUser($req);
        die(json_encode([
            'status' => 'success',
            'avatar' => $currUser['avatar']
        ]));
    }
    if($req['request'] === 'editAvatar'){
        if(!array_key_exists('avatar', $req)) err('MALFORMED_REQUEST');
        $currUser = getRequestingUser($req);
        $image = base64_decode($req['avatar'], true);
        if($image === false) err('MALFORMED_REQUEST');
        $image = imagecreatefromstring($image);
        if($image === false) err('MALFORMED_REQUEST');
        $imgName = md5($req['avatar'] . time() . json_encode($currUser)) . '.png';
        $image = imagescale($image, 256, 256);
        if(imagepng($image , 'avatars/' . $imgName)) {
            $stmt = $conn->prepare("UPDATE users SET avatar = ? WHERE ID=?");
            $stmt->bind_param("si", $imgName, $currUser['ID']);
            $stmt->execute();
            unlink('avatars/' . $currUser['avatar']);
            die(json_encode([
                'status' => 'success',
                'avatar' => $imgName
            ]));
        } else err('MALFORMED_REQUEST');
    }

    if($req['request'] === 'removeAvatar'){
        $currUser = getRequestingUser($req);
        if($currUser['avatar'] != 'generic.png') unlink('avatars/' . $currUser['avatar']);
        
        $stmt = $conn->prepare("UPDATE users SET avatar = 'generic.png' WHERE ID=?");
        $stmt->bind_param("i", $currUser['ID']);
        $stmt->execute();

        die(json_encode([
            'status' => 'success'
        ]));
    }
?>