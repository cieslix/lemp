<?php
error_reporting(E_ALL);
ini_set('display_error', 1);
try {
    $db = new PDO('mysql:host=localhost;dbname=magento;charset=utf8', 'root', 'password');
    $q = $db->query('select * from users');
    $q->execute();
    var_dump($q->fetchAll());
} catch (Exception $e) {
    print_r($e);
}

?>
