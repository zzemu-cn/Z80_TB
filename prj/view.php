<?php
/*
2008-04-22
*/

// 使用了 $_v_ 开头的变量，程序中避免使用
// 全局变量中 _v_list 数组列表 _v_varlist 变量列表
function view_fetch($_v_file, $_v_list='', $_v_varlist='', $_v_path='', $_v_ext='.var')
{
	// 局部参数
	$_v_tmp = $_v_path . basename($_v_file) . $_v_ext;
	if(file_exists($_v_tmp)) include $_v_tmp;

	// 指定的变量
	$_v_a = string_split($_v_list);
	foreach($_v_a as $_v_var) {
		$_v_tmp = "$_v_path$_v_var$_v_ext";
		if(file_exists($_v_tmp)) include $_v_tmp;

		if(isset($GLOBALS[$_v_var])&&is_array($GLOBALS[$_v_var]))
			extract($GLOBALS[$_v_var]);
	}

	$_v_a = string_split($_v_varlist);
	foreach($_v_a as $_v_var) {
		if(isset($GLOBALS[$_v_var]))
			${$_v_var}=$GLOBALS[$_v_var];
	}

	ob_start();
	include $_v_file;
	$_v_tmp = ob_get_contents();
	ob_end_clean();
	return $_v_tmp;
}

function view_show($_v_file, $_v_list='', $_v_varlist='', $_v_path='', $_v_ext='.var')
{
	echo view_fetch($_v_file, $_v_list, $_v_varlist, $_v_path, $_v_ext);
}

function view_fetch_html($file)
{
	return file_get_contents($file);
}

function view_inc($_v_file)
{
	include $_v_file;
}

function string_split($s)
{
	$v = preg_split('/[,;\|]/',$s);
	$v = array_filter($v);
	return $v;
}

// 删除尾部 n 个字符
function trimtail($s, $n=1)
{
	$len = strlen($s)-$n;
	if($len>0)
		return substr($s, 0, $len);
	else
		return '';
}
