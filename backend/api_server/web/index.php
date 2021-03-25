<?php
$conn = new mysqli("localhost","root","","shareapp");
$TUNNEL = ['host' => '127.0.0.1', 'port' => 1415];

set_time_limit(0);
//error_reporting(0);
header('Content-Type: application/json');

include 'includes/utils.php';

// Il body conterrà un messaggio JSON
try {
    $req = json_decode(file_get_contents('php://input'), true);
    // req dovrà contenere almeno le proprietà request ed authentication
    if(!(array_key_exists('request', $req) && array_key_exists('authentication', $req)))
        err('MALFORMED_REQUEST');
    
    // autoloader
    foreach (glob("includes/endpoints/*.php") as $filename) {
        include_once "./$filename";
    }
} catch (Exception $e) { err('MALFORMED_REQUEST'); }

err('NO_ACTION_SPECIFIED');
?>