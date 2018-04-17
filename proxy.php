<html><head><title>CustomWebApp 530</title></head></html>
<h1>Welcome to CustomWebApp 530</h1><br />

<?php
echo 'This web server was connected to from the IP address <strong>'.$_SERVER['REMOTE_ADDR'].'</strong><br /><br />';
if(isset($_SERVER['HTTP_X_FORWARDED_FOR'])){
  echo 'The client being forwarded by the proxy has an IP address of <strong>'.$_SERVER['HTTP_X_FORWARDED_FOR'].'</strong><br /><br />';
} else {
    echo 'Proxy connection not detected.';
}
if(isset($_SERVER['HTTP_VIA'])){
  echo 'Connection forwarded courtesy of <strong>'.$_SERVER['HTTP_VIA'].'</strong><br /><br />';
}
?>