<?php
    function normalizePhoneNumber($number) {
        $number = str_replace(' ', '', $number);
        $startsWithPlus =  ($number[0] == '+');
        if($startsWithPlus) $number = substr($number, 1);
        $areNonNumericals = false;
        for($firstNonNumerical = 0; $firstNonNumerical < strlen($number); $firstNonNumerical++) {
            if(!(
                in_array(
                    $number[$firstNonNumerical],
                    ['0','1','2','3','4','5','6','7','8','9']
                )
            )) {
                $areNonNumericals = true;
                break;
            }
        }
        if($areNonNumericals) $number = substr($number, 0, $firstNonNumerical);
        if($startsWithPlus) $number = '+' .  $number;
        return (strlen($number) > 3) ? $number : null;
    }
    if($req['request'] === 'syncAddressBook'){
        if(!(
            array_key_exists('myPhoneNumber', $req) &&
            array_key_exists('contacts', $req)))
        err('MALFORMED_REQUEST');
        if(!is_array($req['contacts'])) err('MALFORMED_REQUEST');

        $req['myPhoneNumber'] = normalizePhoneNumber($req['myPhoneNumber']);
        if(is_null($req['myPhoneNumber'])) err('MALFORMED_REQUEST');

        foreach($req['contacts'] as &$contact) {
            $contact = normalizePhoneNumber($contact);
        }
        unset($contact);

        $req['contacts'] = array_diff(
            array_unique(array_filter($req['contacts'])),
            [$req['myPhoneNumber']]
        );

        $currUser = getRequestingUser($req);

        $stmt = $conn->prepare("UPDATE users SET phoneNumber=? WHERE ID=?");
        $stmt->bind_param("si", $req['myPhoneNumber'], $currUser['ID']);
        $stmt->execute();

        foreach($req['contacts'] as &$contact) {
            $contact = '("' . $currUser['ID'] . '", "'. $contact . '")';
        }
        unset($contact);
        $req['contacts'] = implode(', ', $req['contacts']);

        if(strlen($req['contacts']) > 3) {
            $stmt = $conn->prepare("INSERT IGNORE INTO rubricaSync (user_ID, phoneNumber) VALUES " . $req['contacts']);
            $stmt->execute();
        }

        $stmt = $conn->prepare("SELECT user_ID as user_A, ID as user_B, rubricaSync.phoneNumber FROM rubricaSync JOIN users ON rubricaSync.phoneNumber = users.phoneNumber");
        $stmt->execute();
        $result = $stmt->get_result();
        $result = $result->fetch_all(MYSQLI_ASSOC);
        
        $insertInRubrica = [];
        $deleteFromRubricaSync = [];

        foreach($result as $record) {
            $insertInRubrica[] = '("' . $record['user_A'] . '", "' . $record['user_B'] . '")';
            $deleteFromRubricaSync[] = '(user_ID = "' . $record['user_A'] . '" AND phoneNumber = "' . $record['phoneNumber'] . '")';
        }
        unset($result);

        $insertInRubrica = implode(', ', $insertInRubrica);
        if(strlen($insertInRubrica) > 3) {
            $stmt = $conn->prepare("INSERT IGNORE INTO rubrica (user_A, user_B) VALUES " . $insertInRubrica);
            $stmt->execute();
        }

        $deleteFromRubricaSync = implode(' OR ', $deleteFromRubricaSync);
        if(strlen($deleteFromRubricaSync) > 3) {
            $stmt = $conn->prepare("DELETE FROM rubricaSync WHERE " . $deleteFromRubricaSync);
            $stmt->execute();
        }

        die(json_encode([
            'status' => 'success'
        ]));
    }
?>