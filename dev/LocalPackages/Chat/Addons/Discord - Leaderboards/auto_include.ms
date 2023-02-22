username	"TatsumaYakoshi"
xp	638910
*/
proc _chat_lb_update_database(@args) {
#check for import leaderboard, and import (database lastedittime)
	@config = import('Chat.config.Discord')
	@leaderboard = import('server.Discord.members.leaderboard', get_value('server.Discord.members.leaderboard'));
	@lastsave = import('server.Discord.members.leaderboard.last.save', (time() + 100000));
	if(@leaderboard['lastedit'] > @lastsave) {
		store_value('server.Discord.members.leaderboard', @leaderboard)
		export('server.Discord.members.leaderboard.last.save', time())
		_write_file(import('Chat.logs.dir').'/Leaderboard_'.reg_replace('\\s', '_', @leaderboard['guild']['name']).'.json', json_encode(@leaderboard), 'OVERWRITE')
	}
}

proc _chat_lb_levelXP(@args) {
@levelxp = array(0, 100)
array_resize(@levelxp, 200)
@mp = 1
foreach(@i: @lvl in @levelxp) {
	if(@i == 0) { @levelxp[0] = 0 }
	if(@i < 2) { continue() }
	switch(@i) {
	case 2:
		@mp = 2.5
	case 3:
		@mp = 2
	case 4:
		@mp = 1.7
	case 5:
		@mp = 1.5
	case 6:
		@mp = 1.4
	case 7:
		@mp = 1.3
	case 8..11:
		@mp = 1.25
	case 12..15:
		@mp = 1.2
	case 16..22:
		@mp = 1.15
	case 23..32:
		@mp = 1.1
	case 33..39:
		@mp = 1.08
	case 40..49:
		@mp = 1.06
	case 50..69:
		@mp = 1.05
	case 70..79:
		@mp = 1.04
	case 80..89:
		@mp = 1.03
	case 90..109:
		@mp = 1.025
	case 110..134:
		@mp = 1.02
	case 135..159:
		@mp = 1.015
	case 160..169:
		@mp = 1.013
	case 170..200:
		@mp = 1.01
	}
	@levelxp[@i] = integer(@levelxp[(@i - 1)] * @mp)
}
export('server.Discord.leaderboard.levelXP', @levelxp)
}