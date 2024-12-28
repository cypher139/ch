<html>
<?php
//Version 0.10
	$instanceOptions = json_decode(file_get_contents("Leaderboard_Servers.json"), true);
	$instanceServerNicknames = array();
	//Get server nicknames
	foreach ($instanceOptions['servers'] as $key => $row){
		$instanceServerNicknames += [ $row['n'] => $key];
	}
	$selectSort = 'level';
	$sortTypes = [
		// json sort key, Sorted by Display, requires Default Direction flip, Sort type Normal, Sort type Reversed (or Normal if default flipped)
		'username' => array('username', 'Username', 1, 'Z-A_9-0.', '.0-9_A-Z'),
		'color' => array('color', 'Role Color', 1, '#F - 0', '#0 - F'),
		'level' => array('level', 'Level', 0, 'Highest to Lowest', 'Lowest to Highest'),
		'xp' => array('xp', 'XP', 0, 'Highest to Lowest', 'Lowest to Highest'),
		'xp_r' => array('xp_remain', 'XP to next Level', 1, 'Highest to Lowest', 'Lowest to Highest'),
		'words' => array('words', "Number of Words", 0, 'Highest to Lowest', 'Lowest to Highest'),
		'msgs' => array('msg_count', 'Number of Messages', 0, 'Highest to Lowest', 'Lowest to Highest'),
		'lastmsg' => array('last_msg', 'Last sent Message', 0, 'Latest to Longest', 'Longest to Latest'),
	];
	if(array_key_exists('sort', $_GET)) {
		switch(strtolower($_GET['sort'])) {
			case 'user':
			case 'username':
				$selectSort = 'username';
				break;
			case 'color':
			case 'usercolor':
			case 'rolecolor':
				$selectSort = 'color';
				break;
			case 'level':
			case 'lvl':
				$selectSort = 'level';
				break;
			case 'xp':
			case 'exp':
				$selectSort = 'xp';
				break;
			case 'xpleft':
			case 'xpremain':
			case 'remain':
				$selectSort = 'xp_r';
				break;
			case 'word':
			case 'words':
				$selectSort = 'words';
				break;
			case 'messages':
			case 'msg':
			case 'message':
			case 'msg_count':
			case 'msgs':
				$selectSort = 'msgs';
				break;
			case 'last':
			case 'lastmsgs':
				$selectSort = 'lastmsg';
				break;
		}
	}			
	$sortType = $sortTypes[$selectSort][0];
	//-----
	$serverID = $instanceOptions['primary'];
	if(array_key_exists('serverid', $_GET)) {
		if(is_numeric($_GET['serverid'])) {
			$serverID = $_GET['serverid'];
			if(!array_key_exists($serverID, $instanceOptions['servers'])) {
				exit("That server does not have an active Leaderboard, or our bot is not active on that server. Recheck your server ID for typos.");
			}		
		} elseif (array_key_exists(strtolower($_GET['serverid']), $instanceServerNicknames)) {
			$serverID = $instanceServerNicknames[strtolower($_GET['serverid'])];
		} else {
			exit("I detected a server name? Sorry, please specify the server's numeric ID to view their leaderboard.");
		}
	}
	$limit = 0;
	if(array_key_exists('limit', $_GET)) {
		if(is_numeric($_GET['limit'])) {
			$limit = abs($_GET['limit']);
		}
	}

	function doSort0($a,$b) {
		//Normal
		global $sortType;
		return $a[$sortType] < $b[$sortType];
	};
	function doSort1($a,$b) {
		//Reverse
		global $sortType;
		return $a[$sortType] > $b[$sortType];
	};
	//Json file suffix, Board type display
	$selectBoard = array('', 'Leaderboard');
	if(array_key_exists('board', $_GET)) {
		switch($_GET['board']) {
			case 'removed':
				echo 1;
				$selectBoard = array("_Removed", "Leaderboard (Removed Users)");
				break;
			default:
				$selectBoard[0] = '';
				$selectBoard[1] = 'Leaderboard';
		}
	}
	echo(var_dump($selectBoard[0]));
	//-----
	$sortDirection = $sortTypes[$selectSort][2];
	if(array_key_exists('direction', $_GET)) {
		switch($_GET['direction']) {
			case 'flip':
			case 'reverse':
				$sortDirection = abs($sortTypes[$selectSort][2] - 1);
				break;
			default:
				$sortDirection = $sortTypes[$selectSort][2];
		}
	}
	$jsonFilename = "{$serverID}/Leaderboard_{$serverID}{$selectBoard[0]}.json";
	if(!file_exists($jsonFilename)) {
		exit("That Leaderboard doesn't exist! Recheck your requested Leaderboard and Server settings before trying again.");
	}
	//-----------------
	// Get and Sort data
	$data = json_decode(file_get_contents($jsonFilename), true);
	$members = $data['members'];
	$levelXP = $data['options']['levelXP'];
	//compute level xp left
	foreach ($members as $key => $row){
		if($row['level'] == 0) {
			continue;
		}	
		$xpleft = $levelXP[($row['level'] + 1)] - $row['xp'];
		$members[$key] += ['xp_remain' => $xpleft];
	}

	// echo is_array($members)? 'Array' : 'not an Array';
	// echo var_dump($members);
	$entrycount = 0;
	$entry0count = 0;
	//  asort($members, SORT_ASC);
	uasort($members, "doSort".$sortDirection);
	$iconFileType = ".webp";
	if(substr( $data['guild']['icon'], 0, 2 ) === "a_") {
		$iconFileType = ".gif";
	}
	$serverAvatar = "https://cdn.discordapp.com/icons/{$serverID}/{$data['guild']['icon']}{$iconFileType}";
	$userAvatarLimit = 110
?>
<head>
	<title><?php echo $data['guild']['name']; ?> <?php echo $selectBoard[1] ?></title>
	<link rel="icon" type="image/x-icon" href="../assets/favicon.ico">
	<link rel="stylesheet" type="text/css" href="/assets/theme.css">
</head>

<body>
	<img src="<?php echo $serverAvatar; ?>" />&nbsp;<b><?php echo $data['guild']['name']; ?> <?php echo $selectBoard[1] ?></b>&nbsp;&nbsp;&nbsp;&nbsp;<a href="../index.html">Main Site</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ServerList Here
	<hr />
	<?php echo $selectBoard[1] ?>&nbsp;&nbsp;&nbsp;&nbsp;<em>Sorted by <?php echo $sortTypes[$selectSort][1] ?> </em><span class="sortdirection">(<?php echo $sortTypes[$selectSort][($sortDirection + 3)] ?>)</span>&nbsp;&nbsp;&nbsp;&nbsp;-- Last Updated <?php echo date("Y-m-d H:i:s", substr($data['lastedit'], 0, 10)); ?><br />
	<table class="leaderboard">
		<tr>
			<td>Position</td>
			<td><a href="index.php?sort=user">Username</a></td>
		<?php if($selectSort == 'lastmsg') { echo "<td>Last sent Message</td>"; } ?>
		<?php if($selectBoard[0] == "_Removed" && $instanceOptions['servers'][$serverID]['ul']) { echo "<td>Left server at:</td>"; } ?>
			<td><a href="index.php?sort=level">Level</a></td>
			<td><a href="index.php?sort=xp">XP</a></td>
			<td><a href="index.php?sort=words">Words</a><br><em><small>*Approximation</small></em></td>
			<td><a href="index.php?sort=msg">Messages</a></td>
			<td><a href="index.php?sort=xpremain">XP to next Level</a></td>
		</tr>
	<?php
	foreach ($members as $key => $row){
		if($row['level'] == 0) { 
			$entry0count++;
			continue;
		}
		// Converted databases or entries from 2023 may not have the words key, revert to default.
		$words = 0;
		if(array_key_exists('words', $row)) { $words = $row['words']; }
		$nick = $row['username'];
		$usedNick = false;
		if(array_key_exists('nickname', $row)) {
			if(!empty($row['nickname'])) {
				$nick = $row['nickname'];
				$usedNick = true;
			}
		}
		$avatar = "https://cdn.discordapp.com/avatars/".$key."/".$row['avatar'].".webp?size=48";
		if(strlen($row['avatar']) == 1) {
			$avatar = "https://cdn.discordapp.com/embed/avatars/".$row['avatar'].".png";
		}
		$usercolor = $row['color'];
		$entrycount++;
	?>
	<tr>
		<td>#<?php echo $entrycount; ?></td>
		<td style="color:#<?php echo $usercolor; ?>"><div class="info-user"><?php if($entrycount < $userAvatarLimit) { echo "<img class=\"avatar\" src=\"".$avatar."\">"; }?>&nbsp;&nbsp;
		<?php echo $nick; ?>
			<span>
		<?php
			if($usedNick && $instanceOptions['servers'][$serverID]['user']) { echo "Username: ".$row['username']."<br>"; }
			if($instanceOptions['servers'][$serverID]['id']) { echo "ID: ".$key; }
		?>
			</span>
			</div>
		</td>
		<?php 
			if($selectSort == 'lastmsg') {
				echo "<td>";
				if($row['last_msg'] != 0) {
					echo date("Y-m-d H:i:s", substr($row['last_msg'], 0, 10));
				}
				echo "</td>";
			}
		?>
		<?php 
			if($selectBoard[0] == "_Removed" && $instanceOptions['servers'][$serverID]['ul']) {
				echo "<td>";
				if($row['removed'] != 0) {
					echo date("Y-m-d H:i:s", substr($row['removed'], 0, 10));
				}
				echo "</td>";
			}
		?>
		<td><?php echo $row['level']; ?></td>
		<td><?php echo number_format($row['xp']); ?></td>
		<td><?php echo number_format($words); ?></td>
		<td><?php echo number_format($row['msg_count']); ?></td>
		<td><?php echo number_format($row['xp_remain']); ?></td>
	</tr>
	<?php 
		if($limit != 0) {
			if($entrycount == $limit) {
				break;
			}
		}
	} ?>
	</table>
	<span class="info-stats">
		<em>Showing</em> <?php echo number_format($entrycount) ?> <em>of</em> <?php echo number_format(count(array_keys($members))); ?> <em>entries.</em>
		<?php if($entry0count > 0) { echo "<br>- ".number_format($entry0count)."<em> entries were at Leaderboard Level 0.</em>"; }?>
		<?php 
			if($data['guild']['members'] > count(array_keys($members))) { 
				$membersleft = $data['guild']['members'] - count(array_keys($members));
				echo "<br>- <em>At least </em>".number_format($membersleft)."<em> server members did not place on the Leaderboard!</em>";
			}
		?>
	</span>
	<hr />
	<br>Do you like this simple leaderboard bot in the style of Mee6, without actually using big bad Mee6? <a href="https://github.com/cypher139/ch/tree/release/dev/DiscordBot">Host your own instance of Cypher139's DiscordBot</a>, or contact cypher139 on Discord to add your server to his main bot.
</body>
</html>