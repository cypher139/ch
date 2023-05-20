<html>
<?php
//Version 0.9
// ------------------------------
	$secretKey = "123"
// -----------------------
	$sortType = 'level';
	if(array_key_exists('sort', $_GET)) {
		$sortType = $_GET['sort'];
	}
	$limit = 0;
	if(array_key_exists('limit', $_GET)) {
		$limit = $_GET['limit'];
	}

	function doSort($a,$b) {
		global $sortType;
		return $a->{$sortType} < $b->{$sortType};
	};
	 
	$json = file_get_contents("{$secretKey}/Leaderboard.json");
	$boardType = 'Leaderboard';
	if(array_key_exists('removed', $_GET)) {
		$json = file_get_contents("{$secretKey}/Leaderboard_Removed.json");
		$boardType = 'Leaderboard (Removed Users)';
	// array_set(@oldlb, @event['userid'], array('removed': time(), 'data': @leaderboard['members'][@event['userid']]))
	}
	$xpjson = file_get_contents("Leaderboard_LevelXP.json");
	$levelxp = json_decode($xpjson);
	$data = get_object_vars(json_decode($json));
	$guild = get_object_vars($data['guild']);
	$members = get_object_vars($data['members']);
	// echo is_array($members)? 'Array' : 'not an Array';
	//echo var_dump($members);
	$entrycount = 0;
	// $totalcount = array_keys($members);
	//  asort($members, SORT_ASC);

	uasort($members, "doSort");
?>
	<head>
	<title><?php echo $data['Guild_Name']; ?> <?php echo $boardType ?></title>
	<link rel="icon" type="image/x-icon" href="../assets/favicon.ico">
	<link rel="stylesheet" type="text/css" href="../assets/theme.css">
</head>

<body>
	<img src="../assets/TMClogo.png" />&nbsp;<b><?php echo $data['Guild_Name']; ?> <?php echo $boardType ?></b>&nbsp;&nbsp;&nbsp;&nbsp;<a href="../index.html">Main Site</a>
	<hr />
	<?php echo $boardType ?>&nbsp;&nbsp;&nbsp;&nbsp;<em>Sorted by <?php echo $sortType ?> </em><br />
<table>
    <tr>
        <td><a href="index.php?sort=username">Username</a></td>
		<td><a href="index.php?sort=level">Level</a></td>
        <td><a href="index.php?sort=xp">XP</a></td>
        <td><a href="index.php?sort=msg_count">Messages</a></td>
		<td>XP to next level</td>
    </tr>
    <?php
        foreach ($members as $key => $row){
			$level = $row->level;
			if($level == 0) { continue; }
            $xp = $row->xp;
            $username = $row->username;
            $msg_count = $row->msg_count;
			$entrycount++;
    ?>
    <tr>
        <td><?php echo $username ?></td>
		<td><?php echo $level ?></td>
        <td><?php echo $xp ?></td>
        <td><?php echo $msg_count ?></td>
		<td><?php 
			$xpleft = $levelxp[($level + 1)] - $xp;
		
		echo $xpleft ?></td>
    </tr>
    <?php 
			if($limit != 0) {
				if($entrycount == $limit) {
					break;
				}
			}
	} ?>
</table>
	<em>Showing</em> <?php echo $entrycount ?> <em>of</em> <?php echo count(array_keys($members)); ?> <em>entries.</em>
</body>
</html>