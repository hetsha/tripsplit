<?php
$adb = 'C:\\Users\\hetsh\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe';
$output = [];
$return_var = -1;
exec("\"$adb\" devices -l 2>&1", $output, $return_var);

echo json_encode([
    'output' => $output,
    'code' => $return_var,
]);
