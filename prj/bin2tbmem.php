<?php
$binname = strval($argv[1]);	// hello.bin
$filename = strval($argv[2]);	// mem.d
$w = intval($argv[3]);			// 字节数

// 读文件
if(strtoupper($bin_name)!='NULL') {
	$buf = file_get_contents($binname);
	if($buf===FALSE) exit;
}

$len = strlen($buf);

$dat = '';

for($i=0;$i<$w;$i++) {
	$dat .= sprintf( "%02X\n", $i<$len ? ord($buf{$i}) : 255 );
}

file_put_contents($filename, $dat);
