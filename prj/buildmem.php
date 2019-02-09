<?php
include_once('view.php');

#$binname = strval($argv[1]);	// hello.bin
$tpl_filename	=	strval($argv[1]);	// ram.v.tpl
$filename		=	strval($argv[2]);	// ram.v
$modulename		=	strval($argv[3]);	// ram_U
$aw				=	intval($argv[4]);	// 14
$dw				=	intval($argv[5]);	// 8
$datfile		=	strval($argv[6]);	// tb/ROM.d
/*
	$off = intval($argv[6]); // offset 偏移
	$spw = intval($argv[7]); // split  划分块数 32位 2位     64位 3位
	//$spn = intval($argv[7]); // split  划分块数 32位 4块     64位 8块
	$spn = pow(2,$spw);
	$spi = intval($argv[8]); // split  划分位置 32位 0 -- 3  64位 0 -- 7
*/

$aw_		=	$aw-1;
$dw_		=	$dw-1;

$MemSize	=	pow(2,$aw);
$MemSize_	=	$MemSize-1;

$vs = compact('modulename', 'aw', 'dw', 'aw_', 'dw_', 'MemSize', 'MemSize_', 'datfile');
file_put_contents($filename, view_fetch($tpl_filename,'vs'));

view_show($tpl_filename,'vs');
