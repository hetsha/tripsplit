<?php
$netsh = 'C:\\Windows\\System32\\netsh.exe';
$out1 = [];
$c1 = -1;
exec("\"$netsh\" advfirewall firewall add rule name=\"Apache_XAMPP_80\" dir=in action=allow protocol=TCP localport=80 2>&1", $out1, $c1);

$out2 = [];
$c2 = -1;
exec("\"$netsh\" advfirewall firewall show rule name=\"Apache_XAMPP_80\" 2>&1", $out2, $c2);

echo json_encode([
    'add_rule' => ['output' => $out1, 'code' => $c1],
    'show_rule' => ['output' => $out2, 'code' => $c2],
]);
