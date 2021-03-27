<?php
    function removePrefix($number) {
        $phonePrefixes = ['1', '20', '210', '211', '212', '213', '214', '215', '216', '217', '218', '219', '220', '221', '222', '223', '224', '225', '226', '227', '228', '229', '230', '231', '232', '233', '234', '235', '236', '237', '238', '239', '240', '241', '242', '243', '244', '245', '246', '247', '248', '249', '250', '251', '252', '253', '254', '255', '256', '257', '258', '259', '260', '261', '262', '263', '264', '265', '266', '267', '268', '269', '27', '290', '291', '295', '297', '298', '299', '30', '31', '32', '33', '34', '350', '351', '352', '353', '354', '355', '356', '357', '358', '359', '36', '370', '371', '372', '373', '374', '375', '376', '377', '378', '379', '380', '381', '382', '383', '385', '386', '387', '388', '389', '39', '40', '41', '420', '421', '423', '43', '44', '45', '46', '47', '48', '49', '500', '501', '502', '503', '504', '505', '506', '507', '508', '509', '51', '52', '53', '54', '55', '56', '57', '58', '590', '591', '592', '593', '594', '595', '596', '597', '598', '599', '60', '61', '62', '63', '64', '65', '66', '670', '671', '672', '673', '674', '675', '676', '677', '678', '679', '680', '681', '682', '683', '684', '685', '686', '687', '688', '689', '690', '691', '692', '7', '800', '808', '81', '82', '84', '850', '852', '853', '855', '856', '86', '870', '875', '876', '877', '878', '879', '880', '881', '882', '883', '886', '90', '91', '92', '93', '94', '95', '960', '961', '962', '963', '964', '965', '966', '967', '968', '969', '970', '971', '972', '973', '974', '975', '976', '977', '979', '98', '991', '992', '993', '994', '995', '996', '998'];
        if($number[0] == '+') {
            foreach($phonePrefixes as $phonePrefix) {
                if(substr($number, 1, strlen($phonePrefix)) == $phonePrefix) {
                    $number = substr($number, strlen($phonePrefix) + 1);
                    break;
                }
            }
        }
        return $number;
    }
    function normalizePhoneNumber($number) {
        $number = str_replace([' ', '(', ')'], '', $number);
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
        if($startsWithPlus) $number = removePrefix('+' .  $number);
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
