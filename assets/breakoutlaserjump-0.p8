pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--breakout laser jump
--by lucasgalib

function _init()

	cartdata("breakout_laser_jump")

	menuitem(1,"reset high scores",reset_hs)

	cls()
	mode="start"
	
	init_variables()
	
	--fade init
	fade_menu=true
	fade_in_timer=40 --frames to fade in
	fade_p=1 --start dark
	
	init_start_blocks()
	
	music(1,400)
end


function _update60()
	update_parts()
	do_blink()
	if mode=="game" then
		update_game()
	elseif mode=="start" then
		update_start()
	elseif mode=="game_over" then
		update_game_over()
	elseif mode=="level_over" then
		update_level_over()
	elseif mode=="winner" then
		update_winner()
	end
end


function _draw()
	--secret palette
	pal(15,128+6,1)
	
	if mode=="game" then
		draw_game()
	elseif mode=="start" then
		draw_start()
	elseif mode=="game_over" then
		draw_game_over()
	elseif mode=="level_over" then
	 draw_level_over()
	elseif mode=="winner" then
	 draw_winner()
	end
	--apply fade effect
	if fade_p>0 then
		fade_screen(fade_p)
	end
end


function init_variables()
	--starting lives
	lives=3
	
	--ball init
	ball={}
	
	--paddle variables
	pad_x=52 
	pad_y=120 
	pad_dx=0 
	pad_dy=0 
	pad_wo=24 --paddle original width
	pad_w=24 --current paddle width
	pad_h=3 --paddle height
	
	--paddle jump variables 
	pad_grounded=true 
	pad_jump_power=-1.3 --jump strength negative=up
	pad_gravity=0.1 --gravity strength
	pad_can_jump=true 
	
	--blocks variables
	block_w=9 
	block_h=4
	spr_lookup={b=40,i=10,h=30,e=50,s=0,p=20,v=60}
	
	--laser variables
	laser_cd_max=600 --tune max cd 
	laser_speed=4 --pixels per frame
	laser_cd=0 
	super_laser_active=false 
	super_laser_flash=0
	initial_serve=false
	
	--score variables
	score=0
	score_mult=1 
	chain=1 
	
	--levels
	levelnum=1 --level 1 init
	level=levels[levelnum]
	
	--sudden death
	sd_block=nil
	sd_timer=0
	sd_thresh=3 --blocks to sd
	
	--power ups variables
	timer_slow=0
	timer_expand=0
	timer_reduce=0
	timer_megaball=0
	timer_megaball_w=0
	
	--shake screen
	shake=0 
	
	-- x button blink
	blink_x_frame=0
	blink_x_i=1
	blink_x_g=7
	blink_x_flash=0
	
	-- z button blink
	blink_z_frame=0
	blink_z_i=1
	blink_z_g=7
	blink_z_flash=0
	
	--arrow preview blink
	arr_b=1 
	arr_b_frame=0
	
	--fade screen
	start_countdown=-1 
	fade_p=0 --fade percentage
	fade_in_timer=0 
	fade_menu=false 
	
	--flash
	flash_time=5 --tune flash time
	
	--sash ui
	sash_w=0 
	sash_dw=0 --destination width
	sash_c=0 
	sash_text=""
	sash_frames=0 
	sash_v=false
	sash_delay_w=0 
	sash_delay_tx=0 
	
	--combo messages
	combo_msgs={"awesome!","so sick!","bonkers!","brilliant!","buenisimo!","on fire!","legendary!","unreal!","insane!","magnificent!"}
	
	--particles
	part={}
	last_hit_dx=0
	last_hit_dy=0
	
	--particle colors
	col_fire={7,10,9,8,2,0}
	col_smoke={0,0,0,5,6}
	col_laser={7,14,8,2}
	col_basic={7,6}
	col_mega={14,2}
	
	--other variables
	top_bar=8 
	sticky=false
	sticky_x=0
	inf_counter=0 --infinite loop protection
	
	--high score
	hs={}
	load_hs()
	hs_x=129 
	hs_dx=129 
	
	--stat tracking current game 
	stat_blocks=0
	stat_powers=0 
	stat_pad_hits=0 
	stat_level=1 
	stat_laser_shots=0 
	stat_victories=0 
end
-->8
--draw


function draw_game()
	cls(0)
	rectfill(0,0,127,127,5)
	do_shake()
	
	draw_paddle()
	draw_blocks()
	draw_top_bar()
	draw_laser_cd()
	draw_pills()
	draw_lasers()
	draw_sash()
	draw_parts()
	draw_ball()
end


function draw_start()
	cls(5)
	draw_parts()
	draw_start_blocks()
	--draw logo with slide offset
	palt(14,true)
	palt(0,false)
	--breakout
	spr(64,37,9+logo_offset_y,7,4)
	--laser
	spr(71,33,41+logo_offset_y,5,2)
	--jump
	spr(76,59,38+logo_offset_y,4,2)
	palt()

	--under sash
	rectfill(0,60,128,68,0)
	print("by lucasgalib",39+(hs_x-129),62,7)
	print("press ❎ to start",31+(hs_x-129),85,blink_x_g)
	print("⬅️ for high scores",29+(hs_x-129),102,0)
	draw_hs(hs_x,65)
	
	--version number
	print("v1.0",hs_x-126,121,0)
end


function draw_level_over()
	draw_game()
	rectfill(0,60,128,68,0)
	print("level "..levelnum.." cleared!",35,62,7)
	print("press ❎ to continue",26,85,blink_x_g)
end


function draw_game_over()
	draw_game()
	rectfill(0,60,128,68,0)
	print("game over!",45+(hs_x-129),62,7)
	print("press ❎ to retry",30+(hs_x-129),80,blink_x_g)
	print("press 🅾️ to exit",32+(hs_x-129),90,blink_z_g)
	print("⬅️ for your score",30+(hs_x-129),102,0)
	draw_stats(hs_x,65)
end


function draw_winner()
	draw_game()
	rectfill(0,60,128,68,0)
	print("congrats! you win!",29+(hs_x-129),62,7)
	print("press 🅾️ to exit",32+(hs_x-129),85,blink_z_g)
	print("⬅️ for your score",30+(hs_x-129),102,0)
	draw_stats(hs_x,65)
end


function draw_ball()
	local ball_spr=34
	for i=1,#ball do
	
	--if megaball
	if timer_megaball>0 or timer_megaball_w>0 then
		ball_spr=35
	end
	spr(ball_spr,ball[i].x-3,ball[i].y-3)
	--serve preview
		if ball[i].stuck 
		and not blocks_intro_active() then
			--draw dots along the aim line (grey to white fade)
			for j=2,5 do
				local dot_x=ball[i].x+ball[i].dx*j*2*arr_b
				local dot_y=ball[i].y+ball[i].dy*j*2*arr_b
				local cols={13,6,6,7,5}
				local ci=((flr(arr_b_frame/6)+j)%3)+1  
				local dot_col=cols[ci]
				circfill(dot_x,dot_y,0.5,dot_col)
			end
		end
	end
end


function draw_paddle()
	palt(0,false)
	palt(14,true)
	if sticky then
		sspr(32,16,5,7,pad_x,pad_y)
		sspr(40,16,5,7,pad_x+pad_w-4,pad_y)
	else
		sspr(0,16,5,7,pad_x,pad_y)
		sspr(8,16,5,7,pad_x+pad_w-4,pad_y)
	end
	--middle part of pad
	for i=5,pad_w-5 do
		if sticky then
			sspr(37,16,1,7,pad_x+i,pad_y)
		else
			sspr(5,16,1,7,pad_x+i,pad_y)
		end
	end
	palt()
	--laser dots on pad
	if laser_cd<=0 then 
		for i=1,3 do
			local c=i<3 and 13 or 8
			pset(pad_x+3,pad_y+i,c)
			pset(pad_x+pad_w-3,pad_y+i,c)
		end
		pset(pad_x+4,pad_y+1,7)
		pset(pad_x+pad_w-4,pad_y+1,7)
	end
end


function draw_top_bar()
	--black bar on top
	rectfill(0,0,128,7,0)
	print("#"..levelnum,1,1,6)
	print("♥"..lives,16,1,6)
	print("score "..score,50,1,6)
	
	--print xcombo
	local xcombo=chain*score_mult
	local xcolor=6
	if xcombo>=8 then
		xcolor=8
	end
	print("x"..xcombo,35,1,xcolor)
end


function draw_blocks()
	local _bspritex=0 
	local i
	
	for i=1,#blocks do
	local _b=blocks[i]
		if _b.v or _b.fsh>0 then
			--flashing state
			if _b.fsh>0 then
				_b.fsh-=1
				_bsprite=false
			else
				--lookup sprite position
				_bspritex=spr_lookup[_b.t]
				_bsprite=_bspritex!=nil
				_bspritex=_bspritex or 0
			end
			--animated position
			local _bx=_b.x+_b.ox
			local _by=_b.y+_b.oy
			if _bsprite then
				palt(0,false)
				palt(14,true)
				pal(11,128+5,1)
				sspr(_bspritex,24,10,5,_bx,_by)
				palt()
			else
				--flash white rectangle
				rectfill(_bx,_by,_bx+block_w-1,_by+block_h-1,7)
			end
		end
	end
end


function draw_pills() 
	palt(11,true)
	palt(0,false)
	for i=1,#pill do 
		spr(pill[i].t,pill[i].x,pill[i].y) 
	end 
	palt()
end

--draw lasers
function draw_lasers()
	for i=1,#laser do
		local l=laser[i]
		if l.super then
			--draw smaller red super laser (3 pixels wide, shorter)
			rectfill(l.x-1,l.y,l.x+1,l.y+4,8) --red outer
			line(l.x,l.y,l.x,l.y+4,14) --pink/light red center line
		else
			--draw normal thin laser
			line(l.x,l.y,l.x,l.y+3,8)
		end
	end
end


function draw_laser_cd()
	--background (empty)
	rectfill(105,2,125,4,5)
	--fill based on cooldown
	local fill=20*(1-laser_cd/laser_cd_max)
	if fill>0 then
		--use red color if super laser is ready
		rectfill(105,2,105+fill,4,super_laser_active and 8 or 6)
	end
end
-->8
--state machine

function update_game()

	--handle fade in
	if fade_in_timer>0 then
		fade_in_timer-=1
		fade_p=fade_in_timer/20 
		if fade_in_timer<=0 then
			fade_p=0
			pal() 
		end
	end
	
	pad_size()
	ball_move()
	pad_move()
	pad_jump()
	shoot_laser()
	pad_collision()
	block_collision()
	laser_collision()
	move_pills()
	move_lasers()
	update_sd()
	check_explosions()
	sticky_shot()
	powerup_timer()
	arrow_blink()
	animate_blocks()
	update_sash()
	
	--check level finished
	if level_finished() then
		_draw()
		if levelnum>=#levels then
			win_game()
		else
			level_over()
		end
	end
	
end


function update_start()

	--block start animation
	update_start_blocks()
	
	--logo slide animation
	if not logo_settled then
		logo_offset_y+=logo_speed
		if logo_offset_y>=0 then
			logo_offset_y=0
			logo_settled=true
		end
	end
	
	--when x pressed to start game
	if btnp(5) then
	 start_accel=true
	 music(-1,950)
	end
	
	--logo speed particles (only after logo settles)
	if logo_settled then
		logo_parts()
	end
	-- handle fade in for menu
	if fade_menu and fade_in_timer>0 then
		fade_in_timer-=1
		fade_p=fade_in_timer/20
		if fade_in_timer<=0 then
			fade_p=0
			fade_menu=false
			pal() 
		end
	end
	
	--slide high scores
	if hs_x!=hs_dx then
		hs_x+=(hs_dx-hs_x)/5
	end
	
	if start_countdown<0 then
		if btnp(5) then
			start_countdown=60 
			sfx(23)
		end
		if btnp(0) and hs_dx!=0 then
			hs_dx=0
		end
		if (btnp(1) or btnp(5) or btnp(4)) and hs_dx!=129 then
			hs_dx=129
		end
	else
		start_countdown-=1
		fade_p=1-(start_countdown/20) 
		if start_countdown<=0 then
			start_countdown=-1
			fade_p=0 
			pal() 
			start_game()
		end
	end
end


function update_game_over()

	if hs_x!=hs_dx then
		hs_x+=(hs_dx-hs_x)/5
	end

	if start_countdown<0 then
		-- retry button (❎)
		if btnp(5) then
			start_countdown=60
			sfx(23)
			exit_to_menu=false
		end

		-- exit button (🅾️)
		if btnp(4) then
			start_countdown=60
			sfx(20)
			exit_to_menu=true
		end

		-- high score sliding
		if btnp(0) and hs_dx!=0 then
			hs_dx=0
		end
		if (btnp(1) or btnp(5) or btnp(4)) and hs_dx!=129 then
			hs_dx=129
		end
	else
	
		-- fade countdown
		start_countdown-=1
		fade_p=1-(start_countdown/20)
		if start_countdown<=0 then
			start_countdown=-1
			fade_p=0
			pal()
			if exit_to_menu then
				_init()
			else
				retry_game()
			end
		end
	end
end


function update_level_over()
	if start_countdown<0 then
		if btnp(5) then
			start_countdown=60 
			sfx(23)
		end
	else
		start_countdown-=1
		fade_p=1-(start_countdown/20)
		if start_countdown<=0 then
			start_countdown=-1
			fade_p=0
			pal()
			next_level()
		end
	end
end


function update_winner()
	if hs_x!=hs_dx then
		hs_x+=(hs_dx-hs_x)/5
	end
	if start_countdown<0 then
		if btnp(4) then
			start_countdown=60
			sfx(23)
		end
		if btnp(0) and hs_dx!=0 then
			hs_dx=0
		end
		if (btnp(1) or btnp(4)) and hs_dx!=129 then
			hs_dx=129
		end
	else
		start_countdown-=1
		fade_p=1-(start_countdown/20)
		if start_countdown<=0 then
			start_countdown=-1 
			fade_p=0 
			pal() 
			_init()
		end
	end
end


function game_over()
	check_hs()
	mode="game_over"
end


function level_over()
	sfx(25)
	mode="level_over"
end


function win_game()
	stat_victories+=1
	check_hs() 
	mode="winner"
	sfx(27)
end


function start_game()
	menuitem(1) --disable menuitem
	init_variables()
	cls()
	mode="game"
	build_blocks(level)
	reset_laser()
	reset_pills()
	serve_ball()
	show_sash("level "..levelnum,0)
	--fade in setup
	fade_in_timer=30
	fade_p=1 --start dark
	sfx(26)
end


function level_finished()
	for i=1,#blocks do
		if blocks[i].v and blocks[i].t!="i" then
			return false
		end
	end
	return true
end


function next_level()
	mode="game"
	--paddle reposition
	pad_x=52 
	pad_y=120 
	pad_dx=0 
	--other variables
	chain=1 
	sticky=false 
	--advance level
	levelnum+=1
	stat_level=levelnum 
	level=levels[levelnum]
	
	reset_laser()
	build_blocks(level)
	serve_ball()
	show_sash("level "..levelnum,0)
	sfx(26)
end

function retry_game()
	
	mode="game"
	
	--variables that change
	lives=3
	local score_penalty=flr(score*0.25)
	score-=score_penalty
	if score<0 then
		score=0
	end
	
	--paddle reposition
	pad_x=52
	pad_y=120 
	pad_dx=0 
	
	--other variables
	chain=1 
	sticky=false
	
	--not advance level
	level=levels[levelnum]
	reset_laser()
	build_blocks(level)
	serve_ball()
	show_sash("score -"..score_penalty,0)
	--fade in setup
	fade_in_timer=30 --frames to fade in
	fade_p=1 --start dark
	sfx(26)
end
-->8
--levels 

--x = empty space
--b = normal block
--h = hardened block
--e = extra hardened block 
--i = indestructible block
--s = exploding block
--p = power up block
--v = invisible block

--level configuration
level=""
levelnum=1
levels={}


--welcome
levels[1]="///xxxb4/xxxb4/xxxb4"

--small pyramid
levels[2]="///xxxxxb/xxxxbbb/xxxbbpbb/xxbbbbbbb"

--power h
levels[3]="//xxxxbxb/xxxxbxb/xxbbbpbbb/xxxxbxb/xxxxbxb/"

--the container
levels[4]="//xxbx4b/xxbx4b/xxbxxpxxb/xxbx4b/xxbx4b/xxb6/"

--intro hard
levels[5]="///xxxxhxh/xxxhhbhh/xxxxbpb/xxxhhbhh/xxxxhxh/"

--the barrier
levels[6]="///x3bbb/x3bpb/x3bbb////xh8"

--the chain
levels[7]="////xhxhxhxhxh/bbbpbbbpbbbxhxhxhxhxh/"

--the tunnel
levels[8]="/xh8//x4b/x3bpb/x4b//xh8/"

--top corners
levels[9]="/xpbbhxhbbp/xbbhxxxhbb/xbhx4hb/xhx6h/xhx6h/"

--intro explosives
levels[10]="/bbbxbbbxbbbbsbxbsbxbsbbbbxbbbxbbb//xxbbbxbbb/xxbsbxbsb/xxbbbxbbb"

--space invader
levels[11]="xxxsxxxs/xxxxsxs/xxxxbbb/xxxbbbbb/xxbbpbpbb/xxb6/xhbbpbpbbh/xhxb4xh/xhxhxxxhxh/xhxhxxxhxh/xxxxhxh/"

--the belt
levels[12]="////h9hbsbsbpbsbsbh9h/"

--dispersed
levels[13]="xhxhxpxhxhx/hxhxhxhxhxh/xhxhxhxhxhx/hxpxhxhxpxh/xhxhxhxhxhx"

--moonflower
levels[14]="/xxxbxxxbb/xxbhbxxxbb/xbhshbxxxpxxxbhbxxxbb/xxxbxxxbb/xxxh/xxxh/xxxh/b9b"

--intro indestructible
levels[15]="xxxxxpxxxx//xxxxbbb//xxxbbbbb//xxbbbbbbb/xxi6"

--the basket
levels[16]="//xxxxbbb/xixxbpbxxi/xixxiiixxi/xixxipixxi/xissixissi/xix6i/xix6i/xi8/"

--double side
levels[17]="xxxi4/x4i/x4i/xbbbxixbbb/xbpbxixbpb/xbbbxixbbb/xbpbxixbpb/xbbbxixbbb/x4i/x4i/xxxi4"

--the jail
levels[18]="/xi3xi3/xix6i/x4h/xixxbbbxxi/xixhbpbhxi/xixxbbbxxi/xixxxhxxxi/xix6i/xi8/"

--explosive center
levels[19]="xxxi4//x3hhh/xxxhshsh/xixh4xi/xixhhphhxi/xixh4xi/xxxhshsh/x3hhh/"

--intro invisibles
levels[20]="///xxv6/xxv6/xxv6"

--the fortress
levels[21]="/xxhhhshhh/xhhsbbbshh/hhbbpbpbbhhhsbbiiibbshhhbbpbpbbhhxhhsbbbshhxxxhhhshhh"

--oinvisible right side
levels[22]="//xbbbxxxvvv/xbpbxxxvpv/xbbbxxxvvv//xbbbxxxvvv/xbpbxxxvpv/xbbbxxxvvv/"

--the capsule
levels[23]="/xh8/xhpx4ph/xhxh4xh/xhxhxsxhxh/xhxhshshxh/xhxhxsxhxh/xhxh4xh/xhpx4ph/xh8/"

--the laberynth
levels[24]="xxxixxxi/xxxixxxi/xixixxxi/xixixsxixi/xixxxixxxi/xixpxixpxi/xixxxixxxi/xi8//v9v"

--intro extra hard
levels[25]="//xxe6/xxex4e/xxex4e/xxexxpxxe/xxex4e/xxex4e/xxe6/"

--super extras
levels[26]="//xe3pe3/xeeseeesee/xe8/xepesesepe/xe8/xeeseeesee/xe3pe3/"

--protected blocks
levels[27]="/xxpxexexp/xxixixixi///xxxexpxe/xxxixixi///xxpxexexp/xxixixixi/"

--the cascade
levels[28]="x4i/xxxeepee/xeexxixxee/xxxhhphh/xhhxxixxhh/xxxbbpbb/xbbxxixxbb/xxxvvpvv/xvvx4vv/"

--the umbrella
levels[29]="x4i/xxxhhiee/xxhhbpbee/xhhbpbpbee/xhhbpbpbee/xhhpbbbpee/xixixixixi/x4i/x4i/x4i/xxxsxs/xxxsss/x3s/"

--encrusted diamond
levels[30]="b4xb4bsbbxxxbbsbbbbx4bbbbbxxxexxxbbbxxxesexxxbxxxebpbe/xxxebpbe/bxxxesexxxbbbxxxexxxbbbbbx4bbbbsbbxxxbbsbb4xb4/"

--the preboss
levels[31]="xxxv4/xxv6/xveeeveeev/xvepevepev/xeepeeepee/xveeeveeev/xv8/xxv6/xxvxvxvxv/xxvxvxvxv/xvvxvxvxvv/"

--the final boss
levels[32]="xxxh4/xxh6/xheeeheeeh/xhepehepeh/xeepeeepee/xheeeheeeh/xh8/xxhhssshh/xxh6/xxhphphph/xhhxhxhxhh/xhxxhxhxxh/xhxhhxhhxh/"

-->8
--paddle

function pad_move()

	local buttpress=false --variable button pressed
	pad_x+=pad_dx --movement
	--keeps pad on-screen
	pad_x=mid(0,pad_x,127-pad_w)
	--left move
	if btn(⬅️) then 
		buttpress=true
		pad_dx=-1.5 --speed tune
	end
	--right move
	if btn(➡️) then
		buttpress=true
		pad_dx=1.5 --speed tune
	end
	--slow down
	if not (buttpress) then
		pad_dx/=2.5 --slow tune
	end
	if not pad_grounded and not (btn(⬅️) or btn(➡️)) then
	pad_dx*=0.95
	end
end


function pad_jump()
	if blocks_intro_active() then return end
	--apply gravity
	pad_dy+=pad_gravity
	pad_y+=pad_dy
	--ground collision
	if pad_y>=120 then
		pad_y=120
		pad_dy=0
		pad_grounded=true
	else
		pad_grounded=false
		pad_can_jump=false --reset jump flag when in air
	end
	--jump input - only if grounded and can jump
	if btn(🅾️) and pad_grounded and pad_can_jump then
		pad_dy=pad_jump_power
		pad_grounded=false
		pad_can_jump=false --prevent further jumps until button released
		sfx(16) --jump sound 
	end
	--reset jump ability when button is released
	if not btn(🅾️) then
		pad_can_jump=true
	end
	--extra horizontal speed while in air
	if not pad_grounded then
		if btn(⬅️) then
			pad_dx=-2.5 --faster left in air (was -1.5)
		end
		if btn(➡️) then
			pad_dx=2.5 --faster right in air (was 1.5)
		end
	end
	--keep paddle visible (don't jump too high)
	if pad_y<top_bar+1 then
		pad_y=top_bar+1
		pad_dy=0
	end
	if abs(pad_dx)>=2 then
		spawn_speedlines(pad_x,pad_y,pad_dx)
	end
end


function sticky_shot()
	--don't allow release during block intro
	if blocks_intro_active() then return end
	-- find first stuck ball
	local stuck_ball=nil
	for i=1,#ball do
		if ball[i].stuck then
			stuck_ball=ball[i]
			break
		end
	end
	-- release stuck ball on button press
	if btnp(🅾️) and stuck_ball then
		stuck_ball.stuck=false
		stuck_ball.x=mid(3,stuck_ball.x,124)
		sticky=false
		initial_serve=false --ball is now in play
		inf_counter=0
	end
	-- only allow aiming / catching if there is a stuck ball
	if stuck_ball then
		if btn(⬅️) then 
			stuck_ball.dx=-1
			stuck_ball.dy=-1
		end
		if btn(➡️) then 
			stuck_ball.dx=1
			stuck_ball.dy=-1
		end
	end
end


function pad_size()
	--check if pad should grow
	if timer_expand>0 then
		pad_w=flr(pad_wo*1.5)
	--check if pad should shrink
	elseif timer_reduce>0 then
		pad_w=flr(pad_wo/2)
		score_mult=2 --score mult 
	else
		pad_w=pad_wo
		score_mult=1 
	end
	--clamp sticky_x to new paddle width
	if sticky then
		sticky_x=mid(2,sticky_x,pad_w-2)
	end
end
-->8
--ball
 

function new_ball()
	b={}
	b.x=0 --x position
	b.y=0 --y position
	b.dx=0 --x delta
	b.dy=0 --y delta
	b.r=2 --radius
	b.prev_x=0 --previous frame x
	b.prev_y=0 --previous frame y
	b.stuck=false --stuck
	return b
end


function ball_move()
	for bi=#ball,1,-1 do
		local b=ball[bi]
		--if megaball increase radius
		if timer_megaball>0 then
			b.r=3
		else
			b.r=2
		end
		--if sticky on
		if b.stuck then
			b.x=pad_x+sticky_x --ball on pad x
			b.y=pad_y-b.r-1 --ball on pad y
		--if sticky off
		else
		--regular ball physics
			--ball previous frame
			b.prev_x=b.x  
			b.prev_y=b.y
			--particle trail
			spawn_trail(b.x,b.y)
			--checks for slow motion
			if timer_slow>0 then
				--slow ball movement
				b.x+=(b.dx/3)
				b.y+=(b.dy/2)
			else
				--normal ball movement
				b.x+=b.dx
				b.y+=b.dy
			end
			--bounce right wall
			if b.x+b.r>127 then
				b.x=127-b.r
				b.dx=-b.dx
				sfx(11) 
				puff_smoke(b.x,b.y)
				check_inf(bi)
				check_sd()
			--bounce left wall
			elseif b.x-b.r<0 then
				b.x=b.r
				b.dx=-b.dx
				sfx(11)
				puff_smoke(b.x,b.y)
				check_inf(bi)
				check_sd()
			end
			--bounce bottom wall
			if b.y+b.r>127 then
				--delete this ball
				spawn_death(b.x,b.y)
				shake=0.1
				del(ball,b)  
				if #ball<=0 then 
					shake=0.5
					lives-=1
					sfx(19) 
					if lives<=0 then
						game_over()
					else
						serve_ball()
				end
			end
			--bounce top wall
			elseif b.y-b.r<top_bar then
				b.y=top_bar+b.r
				b.dy=-b.dy
				sfx(11)
				puff_smoke(b.x,b.y)
				check_inf(bi)
				check_sd()
			end
		end
	end
end


function serve_ball()
	--resets balls
	ball={}
	--set up first ball
	ball[1]=new_ball()
	ball[1].r=2
	ball[1].x=pad_x+flr(pad_w/2) --ball on pad x
	ball[1].y=pad_y-ball[1].r-1 --ball on pad y
	ball[1].dx=1 --ball x speed tune
	ball[1].dy=-1 --ball y speed tune
	ball[1].stuck=true 
	--reset chain
	chain=1
	score_mult=1
	--sticks ball mid pad
	sticky_x=flr(pad_w/2) 
	--reset power ups
	timer_slow=0
	timer_expand=0
	timer_reduce=0
	timer_megaball=0
	timer_megaball_w=0
	reset_pills() 
	--laser on cooldown
	initial_serve=true
	laser_cd=laser_cd_max 
	super_laser_active=false --reset super laser
	super_laser_flash=0
	--infinite protection
	inf_counter=0
end


function multi_ball()
	local ballnum=flr(rnd(#ball))+1
	local ogball=ball[ballnum]
	--only spawn if not too many balls
	if #ball>=5 then return end
	--normalize the source ball's speed
	local base_dx=ogball.dx
	local base_dy=-1  -- always use standard vertical speed
	--create new ball with spread angles
	ball2=copy_ball(ogball)
	
	--split in opposite horizontal direction (gentler)
	if base_dx > 0 then
		ball2.dx = -abs(base_dx) - (0.1 + rnd(0.2))  -- goes left
		ogball.dx = abs(base_dx) + (0.1 + rnd(0.2))  -- goes right
	else
		ball2.dx = abs(base_dx) + (0.1 + rnd(0.2))   -- goes right
		ogball.dx = -abs(base_dx) - (0.1 + rnd(0.2)) -- goes left
	end
	
	ball2.dy = base_dy + (rnd(0.4)-0.2)
	ogball.dy = base_dy + (rnd(0.4)-0.2)
	
	--add new ball to array
	ball2.stuck=false
	ball[#ball+1]=ball2
end


function copy_ball(ob)
	b={}
	b.x=ob.x
	b.y=ob.y
	b.dx=ob.dx
	b.dy=ob.dy
	b.prev_x=ob.x  
	b.prev_y=ob.y 
	b.r=ob.r 
	b.stuck=false  
	return b
end


function any_ball_stuck()
	for i=1,#ball do
		if ball[i].stuck then 
			return true 
		end 
	end
	return false
end


function check_inf(bi)
	if ball[bi] and not ball[bi].stuck then
		inf_counter+=1
		if inf_counter>30 then
			inf_counter=0
			--change ball angle randomly
			ball[bi].dx+=rnd(0.7)-0.35
			ball[bi].dx=mid(-3,ball[bi].dx,3)
			if abs(ball[bi].dx)<0.6 then
				ball[bi].dx=ball[bi].dx>0 and 0.6 or -0.6
			end
			--nudge ball position to escape
			ball[bi].x+=rnd(4)-2
			ball[bi].y+=rnd(4)-2
			--keep in bounds
			ball[bi].x=mid(ball[bi].r,ball[bi].x,127-ball[bi].r)
			ball[bi].y=mid(top_bar+ball[bi].r,ball[bi].y,126)
		end
	end
end
-->8
--collisions


function score_hit(_combo,_psfx)
	score+=chain*score_mult
	if _combo then
		if chain==7 then
			show_sash(combo_msgs[flr(rnd(10))+1],0)
		end
		chain+=1
		chain=mid(1,chain,8)
	end
	if _psfx then
		sfx(chain)
	end
end

function ball_box(bi,box_x,box_y,box_w,box_h)
	if ball[bi].y+ball[bi].r<box_y then return false end
	if ball[bi].y-ball[bi].r>box_y+box_h then return false end
	if ball[bi].x+ball[bi].r<box_x then return false end
	if ball[bi].x-ball[bi].r>box_x+box_w then return false end
	return true
end


function box_box(box1_x,box1_y,box1_w,box1_h,box2_x,box2_y,box2_w,box2_h)
	if box1_y>box2_y+box2_h then return false end
	if box1_y+box1_h<box2_y then return false end
	if box1_x>box2_x+box2_w then return false end
	if box1_x+box1_w<box2_x then return false end
	return true
end


function pad_collision()
	for i=1,#ball do 
		if not ball[i].stuck then
			if ball_box(i,pad_x,pad_y,pad_w,pad_h) then
				--push ball out of pad
				ball[i].y=pad_y-ball[i].r
				--reverse vertical speed
				if ball[i].dy>0 then ball[i].dy=-ball[i].dy end
				--catch ball power up
				if sticky and not any_ball_stuck() then
					ball[i].stuck=true
					sticky=true
					sticky_x=mid(ball[i].r,ball[i].x-pad_x,pad_w-ball[i].r)
					ball[i].dx=ball[i].dx>0 and 1 or -1  
					ball[i].dy=-1 
					chain=1
					sfx(18)
					stat_pad_hits+=1
					inf_counter=0
				else
					--normal bounce
					local hit_pos=(ball[i].x-(pad_x+pad_w/2)) / (pad_w/2)
					--tune max horizontal speed (base speed)
					local base_dx=hit_pos*1.25
					--apply jump boost to base speed
					if not pad_grounded then
						ball[i].dx=base_dx*1.25 --boost from base
					else
						ball[i].dx=base_dx --normal speed
					end	
					--cap maximum speed
					ball[i].dx=mid(-3,ball[i].dx,3)
					--reset vertical speed to base value
					ball[i].dy=-0.75
					--apply vertical boost if jumping
					if not pad_grounded then
						ball[i].dy*=1.5
					end
					--minimum speed check
					if abs(ball[i].dx)<0.6 then
						ball[i].dx=ball[i].dx>0 and 0.6 or -0.6
					end
					
					--hit happens
					chain=1
					sfx(0) 
					puff_smoke(ball[i].x,ball[i].y)
					stat_pad_hits+=1
					inf_counter=0
					check_sd()
				end
			end
		end
	end
end


function block_collision()
	for bi=1,#ball do
		local b=ball[bi]
		local closest_block=nil
		local min_dist=999
		--find closest block
		for i=1,#blocks do
			if blocks[i].v then
				local bw=block_w
				if blocks[i].t=="i" then bw=block_w+1 end
				--use animated position
				local block_x=blocks[i].x+blocks[i].ox
				local block_y=blocks[i].y+blocks[i].oy
				local check_x=block_x-1
				local check_y=block_y-1
				local check_w=bw+1
				local check_h=block_h+1
				if ball_box(bi,check_x,check_y,check_w,check_h) then
					local block_center_x=block_x+bw/2
					local block_center_y=block_y+block_h/2
					local dist=abs(b.prev_x-block_center_x)+abs(b.prev_y-block_center_y)
					if dist<min_dist then
						min_dist=dist
						closest_block=i
					end
				end
			end
		end
		--collide with closest block only
		if closest_block then
			local i=closest_block
			local bw=block_w
			if blocks[i].t=="i" then bw=block_w+1 end
			--use animated position here too
			local block_x=blocks[i].x+blocks[i].ox
			local block_y=blocks[i].y+blocks[i].oy
			if (timer_megaball<=0 and timer_megaball_w<=0) or blocks[i].t=="i" then				--save last hit direction
				last_hit_dx=b.dx
				last_hit_dy=b.dy
				-- use ball's own prev fields for collision direction
				local from_left=b.prev_x+b.r<block_x
				local from_right=b.prev_x-b.r>block_x+bw
				local from_top=b.prev_y+b.r<block_y
				local from_bottom=b.prev_y-b.r>block_y+block_h
				if from_left then
					b.dx=-abs(b.dx)
					b.x=block_x-b.r-1
				elseif from_right then
					b.dx=abs(b.dx)
					b.x=block_x+bw+b.r+1
				elseif from_top then
					b.dy=-abs(b.dy)
					b.y=block_y-b.r-1
				elseif from_bottom then
					b.dy=abs(b.dy)
					b.y=block_y+block_h+b.r+1
				else
					--corner hit: reverse both
					b.dx=-b.dx
					b.dy=-b.dy
				end
			end
			--hit happens
			hitting_block(i,true,true,bi)
			check_inf(bi)
		end
	end
end


function destroy_block(_i,_combo,_psfx,_is_ball)
	blocks[_i].v=false
	score_hit(_combo,_psfx)
	blocks[_i].fsh=flash_time
	shatter_block(blocks[_i],last_hit_dx,last_hit_dy)
	stat_blocks+=1
	inf_counter=0
	if _is_ball then
		megaball_smash()
	end
end


--downgrade hard blocks
function downgrade_block(_i,new_t,_combo,_psfx)
	blocks[_i].t=new_t
	score_hit(_combo,_psfx)
	blocks[_i].fsh=flash_time
	shatter_block(blocks[_i],last_hit_dx,last_hit_dy)
	stat_blocks+=1
	inf_counter=0
end


function hitting_block(_i,_combo,_psfx,bi)
	if _psfx==nil then _psfx=true end
	local is_ball = bi != nil
	local t=blocks[_i].t
	
	--force destroy sudden death block
	if blocks[_i]==sd_block then
		destroy_block(_i,_combo,_psfx,is_ball)
		return
	end
	
	--normal block
	if t=="b" then
		destroy_block(_i,_combo,_psfx,is_ball)
	--indestructible block
	elseif t=="i" then
		sfx(12)
		if bi then puff_smoke(ball[bi].x,ball[bi].y) end
	--hard block
	elseif t=="h" then
		if timer_megaball>0 or timer_megaball_w>0 then
			destroy_block(_i,_combo,_psfx,is_ball)
		else
			downgrade_block(_i,"b",_combo,_psfx)
		end
	--extra hard block
	elseif t=="e" then
		if timer_megaball>0 or timer_megaball_w>0 then
			destroy_block(_i,_combo,_psfx,is_ball)
		else
			downgrade_block(_i,"h",_combo,_psfx)
		end
	--power-up block
	elseif t=="p" then
		destroy_block(_i,_combo,_psfx,is_ball)
		spawn_pills(blocks[_i].x,blocks[_i].y)
	--exploding block
	elseif t=="s" then
		downgrade_block(_i,"zz",_combo,_psfx)
	--burning block
	elseif t=="zz" then
		blocks[_i].v=false
		score_hit(_combo,_psfx)
		stat_blocks+=1
	--invisible block
	elseif t=="v" then
		destroy_block(_i,_combo,_psfx,is_ball)
		--flash all other invisible blocks
		for j=1,#blocks do
			if blocks[j].t=="v" and blocks[j].v then
				blocks[j].fsh=flash_time*12
			end
		end
	end
end
-->8
--power ups

--_t=1 speed down 
--_t=2 life +1 
--_t=3 sticky 
--_t=4 expand pad 
--_t=5 reduce pad
--_t=6 megaball
--_t=7 multiball 
--_t=8 super laser


function reset_pills()
	--pill object
	pill={}
end


function spawn_pills(_x,_y)
	local _t,_pill
	--weighted types life appears more often
	local weights={1,2,2,3,4,5,6,7,8}
	_t=weights[flr(rnd(#weights))+1]
	--pill object
	_pill={x=_x,y=_y,t=_t}
	add(pill,_pill)
end


function move_pills()
	for i=#pill,1,-1 do
		local p=pill[i]
		-- fall speed
		p.y+=0.75
		-- off screen
		if p.y>128 then
			del(pill,p)
		-- collision with pad
		elseif box_box(p.x,p.y,8,8,pad_x,pad_y,pad_w,pad_h) then
			powerup_get(p.t)
			puff_pill(p.x,p.y,p.t)
			del(pill,p)
		end
	end
end


function powerup_timer()
	if timer_slow>0 then
		timer_slow-=1
	end
	if timer_expand>0 then
		timer_expand-=1
	end
	if timer_reduce>0 then
		timer_reduce-=1
	end
	if timer_megaball>0 then
		timer_megaball-=1
	end
end


function powerup_get(_p)
	sfx(13)
	stat_powers+=1 
	--slowdown
	if _p==1 then
		timer_slow=300 --timer tune
		show_sash("slowdown!",9)
		sfx(9)
	--life up
	elseif _p==2 then
		lives+=1
		show_sash("♥ +1 life! ♥",8)
		sfx(10)
	--sticky shot
	elseif _p==3 then
	show_sash("sticky!",3)
	-- check if any ball is already stuck
		local any_stuck=false
		for i=1,#ball do
			if ball[i].stuck then
				any_stuck=true
				break
			end
		end
		-- only activate sticky if no balls are stuck
		if not any_stuck then
			sticky=true
		end
	--expand
	elseif _p==4 then
		show_sash("expand!",12)
		timer_expand=800 
		timer_reduce=0
	--reduce
	elseif _p==5 then
		show_sash("reduce!",13)
		timer_reduce=800 
		timer_expand=0
	--megaball
	elseif _p==6 then
		show_sash("megaball!",14)
		timer_megaball_w=600
		timer_megaball=0
	--multiball
	elseif _p==7 then
		show_sash("multiball!",2)
		multi_ball()
	--super laser
	elseif _p==8 then
		show_sash("super laser!",4)
		super_laser_active=true
	end
end


function megaball_smash()
	if timer_megaball_w>0 then
		timer_megaball_w=0
		timer_megaball=180
	end
end

-->8
--laser


function reset_laser()
	--laser object
	laser={} 
end
 

function shoot_laser()
	--check if cooldown just finished
	if laser_cd==1 then
		sfx(17) --laser ready sound
		laser_puff(pad_x+1+pad_w/2,pad_y-2,false,true)
	end
	--decrease cooldown
	if laser_cd>0 and not initial_serve then
		laser_cd-=1
	end
	--decrease flash timer (handles both positive and negative)
	if super_laser_flash>0 then
		super_laser_flash-=1
	elseif super_laser_flash<0 then
		super_laser_flash+=1 --count up towards 0 for normal laser
	end
	--super laser shot
	if btnp(❎) and super_laser_active and laser_cd<=0 then
		add(laser,{x=pad_x+2, y=pad_y-2, super=true})
		add(laser,{x=pad_x+pad_w-2, y=pad_y-2, super=true})
		laser_cd=laser_cd_max --reset cooldown
		super_laser_flash=4 --4 frames of center flash
		super_laser_active=false
		laser_puff(pad_x+2,pad_y-2,true)
		laser_puff(pad_x+pad_w-2,pad_y-2,true)
		stat_laser_shots+=1
		sfx(21) 
		shake=0.1
	--normal laser shot
	elseif btnp(❎) and laser_cd<=0 then
		--shoot from left side
		add(laser,{x=pad_x+2, y=pad_y-2, super=false})
		--shoot from right side
		add(laser,{x=pad_x+pad_w-2, y=pad_y-2, super=false})
		--reset cooldown
		laser_cd=laser_cd_max
		--trigger side flashes (negative = normal)
		super_laser_flash=-2 --2 frames of side flashes
		sfx(14) --laser shot sound
		laser_puff(pad_x+pad_w/2, pad_y-2,false)
		stat_laser_shots+=1
	elseif btnp(❎) and laser_cd>0 then
		sfx(24) --no laser available
	end
end  


function move_lasers()
	for i=#laser,1,-1 do
		laser[i].y-=laser_speed --move up
		--remove if off screen
		if laser[i].y<top_bar then
			del(laser,laser[i])
		end
	end
end


function laser_collision()
	--local laser_sfx=false
	for i=#laser,1,-1 do
		local should_destroy_laser=false
		--collect all blocks the laser hits this frame
		local hits={}
		for j=1,#blocks do 
			if blocks[j].v then
				--check if laser hits block
				--laser size
				local laser_width=laser[i].super and 3 or 2
				local laser_left=laser[i].x-flr(laser_width/2)
				local laser_right=laser[i].x+flr(laser_width/2)
				local laser_top=laser[i].y
				local laser_bottom=laser[i].y+(laser[i].super and 6 or 3)
				if laser_right>=blocks[j].x 
				and laser_left<=blocks[j].x+block_w
				and laser_bottom>=blocks[j].y
				and laser_top<=blocks[j].y+block_h then
					add(hits,j)
				end
			end
		end
		--process all hits
		for h=1,#hits do
			local j=hits[h]
			if laser[i].super then
				--indestructible blocks stop super laser
				if blocks[j].t=="i" then 
					sfx(12)
					should_destroy_laser=true
					laser_puff(laser[i].x,laser[i].y,true)
					break
				else
					--destroy block but keep going
					last_hit_dx=0
					last_hit_dy=-1
					hitting_block(j,false,false,nil)
					laser_puff(laser[i].x,laser[i].y,true)
					--no break here - keeps penetrating!
				end
			else
				--normal laser: destroy on first hit
				if blocks[j].t!="i" then
					last_hit_dx=0
					last_hit_dy=-1
					laser_puff(laser[i].x,laser[i].y,true)
					hitting_block(j,false,false,nil)
				else
					sfx(12)
					laser_puff(laser[i].x,laser[i].y,true)
				end
				should_destroy_laser=true
				break
			end
		end
		--remove laser if needed
		if should_destroy_laser then
			del(laser,laser[i]) 
		end
	end
end
-->8
--blocks 


function add_blocks(_i,_t)
	local _b
	_b={}
	_b.x=4+((_i-1)%11)*(block_w+2)
	_b.y=14+flr((_i-1)/11)*(block_h+2)
	_b.dx=0 --speed
	_b.dy=0 
	_b.v=true --alive
	_b.t=_t --type
	_b.fsh=0 --flashing
	_b.anim_t=0 
	_b.anim_max=100 --intro timer
	--start above screen
	_b.ox=0
	_b.oy=-150
	--add blocks to array
	add(blocks,_b)
end


function build_blocks(lvl)
	local i,j,o,char,last
	last=""
	j=0 --another i type variable
	--block object
	blocks={}
	--valid block types
	local valid={b=1,i=1,h=1,s=1,p=1,v=1,e=1}
	for i=1,#lvl do
		j+=1
		char=sub(lvl,i,i)
		if valid[char] then
			last=char
			add_blocks(j,char)
		elseif char=="x" then
			last="x"
		elseif char=="/" then
			j=(flr((j-1)/11)+1)*11
		elseif char>="0" and char<="9" then
			for o=1,char+0 do
				if valid[last] then
					add_blocks(j,last)
				end
				j+=1
			end
			j-=1
		end
	end
end


function check_explosions()
	for i=1,#blocks do
		if blocks[i].t=="zz" and blocks[i].v then
			blocks[i].t="z"
		elseif blocks[i].t=="z" and blocks[i].v then
			explode_blocks(i)
			spawn_explosion(blocks[i].x,blocks[i].y)
			sfx(22)
			if shake<0.3 then
				shake+=0.1
			end
		end
	end
end


function explode_blocks(_i)
	blocks[_i].v=false
	--explode nearby blocks
	for j=1 ,#blocks do
		if j!=_i 
		and blocks[j].t!="i"
		and blocks[j].v==true
		and abs(blocks[j].x-blocks[_i].x)<=(block_w+2)
		and abs(blocks[j].y-blocks[_i].y)<=(block_h+2)
		then
			--force destroy hardened blocks in explosion
			if blocks[j].t=="h" or blocks[j].t=="e" then
				blocks[j].v=false
				score_hit(false,false)
				blocks[j].fsh=flash_time
				shatter_block(blocks[j],last_hit_dx,last_hit_dy)
    stat_blocks+=1
			else
				hitting_block(j,false,false)
			end
		end
	end
end




------- sudden death -------

function check_sd()
	local c=0 --block counter
	
	if sd_block!=nil then return end
	for i=1,#blocks do
		if blocks[i].v==true and blocks[i].t!="i" then
			c+=1
		end
	end
	if c>sd_thresh then return end
	if c<=sd_thresh then trigger_sd() end
end


function trigger_sd()
	--collect eligible blocks
	local eligible={}
	for i=1,#blocks do
		if blocks[i].v==true and blocks[i].t!="i" then
			add(eligible, blocks[i])
		end
	end
	
	--pick random block
	if #eligible>0 then
		sd_block=eligible[flr(rnd(#eligible))+1]
		show_sash("time bomb!",0)
		sd_timer=450
		sd_blinkt=sd_timer/10
		sd_block.fsh=flash_time
		sfx(28)
	end
end


function update_sd()
	if sd_block!=nil then
		--check if block was destroyed by player
		if sd_block.v==false then
			score+=10
			sd_block.v=true
			sd_block.t="zz"
			sd_block=nil
			return
		end
		
		sd_timer-=1
		if sd_timer<1 then
			sd_block.t="zz"
			sd_block=nil
			return
		end
		sd_blinkt-=1
		if sd_blinkt<1 then
			sd_block.fsh=flash_time
			sd_blinkt=max(sd_timer/10,8)
			sfx(28)
		end
	end
end







---- intro block animation ----


function blocks_intro_active()
	return #blocks>0 and blocks[1].anim_t<blocks[1].anim_max
end


function animate_blocks()
	for i=1,#blocks do
		local _b=blocks[i]
		if _b.v or _b.fsh>0 then
			--intro animation
			if _b.anim_t<_b.anim_max then
				_b.anim_t+=1
				local t=_b.anim_t/_b.anim_max  
				_b.oy=-150*(1-t)  
			else
				--destroyed block physics
				if not _b.v then
					_b.ox+=_b.dx
					_b.oy+=_b.dy
					_b.dx*=0.1
					_b.dy*=0.1
					_b.dy+=0.1 --gravity
				end
			end
		end
	end
end


function rnd_block_type()
	local r=rnd()
	if r<0.90 then return "b"     --90% normal
	elseif r<0.92 then return "h" --2% hard
	elseif r<0.94 then return "e" --2% extra hard
	elseif r<0.96 then return "s" --2% exploding
	elseif r<0.98 then return "p" --2% power
	else return "i" end           --2% indestructible
end


function init_start_blocks()
	start_speed,start_accel,start_y_off=0.5,false,0
	start_step=block_h*3
	start_rows=flr(128/start_step)+3
	start_col_h=start_rows*start_step
	start_wrap_i=start_rows --track which block wraps next
	start_types={}
	for i=1,start_rows do
		start_types[i]=rnd_block_type()
	end
	--logo slide animation
	logo_offset_y=-100
	logo_speed=0.5
	logo_settled=false
end


function update_start_blocks()
	--button press acceleration
	if start_accel then 
		start_speed=2
	end
	
	local prev=flr(start_y_off/start_step)
	start_y_off+=start_speed
	if flr(start_y_off/start_step)!=prev then
		start_types[start_wrap_i]=rnd_block_type()
		start_wrap_i-=1
		if start_wrap_i<1 then 
			start_wrap_i=start_rows 
		end
	end
end


function draw_start_blocks()
	palt(0,false)
	palt(14,true)
	pal(11,128+5,1)
	--x position of colum 1 and 2
	local cols={5,113} 
	for col=1,2 do
		local bx=cols[col]
		for i=1,start_rows do
			local by=((i-1)*start_step+start_y_off)%start_col_h-start_step
			--appear in between 
			if by>-6 and by<60 then
				sspr(spr_lookup[start_types[i]] or 40,24,10,5,bx,by)
			end
		end
	end
	palt()
end
-->8
--sash ui


function show_sash(_t,_c)
	sash_w=0 
	sash_dw=4 
	sash_c=_c 
	sash_text=_t
	sash_tx=-#sash_text*4
	sash_tdx=64-(#sash_text*2)
	sash_frames=0 
	sash_v=true
	sash_delay_w=0
	sash_delay_tx=8
end


function update_sash()
	if sash_v then
		sash_frames+=1
		--animate width
		if sash_delay_w>0 then
			sash_delay_w-=1
		else
			sash_w+=(sash_dw-sash_w)/5
			if abs(sash_dw-sash_w)<0.3 then
				sash_w=sash_dw
			end
		end
		--animate text
		if sash_delay_tx>0 then
			sash_delay_tx-=1
		else
			sash_tx+=(sash_tdx-sash_tx)/10
			if abs(sash_tx-sash_tdx)<0.3 then
				sash_tx=sash_tdx
			end
		end
		--make sash go away
		if sash_frames==85 then
			sash_dw=0
			sash_tdx=160
			sash_delay_w=15
			sash_delay_tx=00
		end
		if sash_frames>115 then
			sash_v=false
		end
	end
end


function draw_sash()
	if sash_v then
		rectfill(0,64-sash_w,128,64+sash_w,sash_c)
		print(sash_text,sash_tx,62,7)
	end
end
-->8
--particles

--type=0 - static pixel
--type=1 - gravity pixel
--type=2 - smoke
--type=3 - chunk
--type=4 - line


function add_part(_x,_y,_dx,_dy,_type,_maxage,_col,_s)
	local _p={}
	_p.x=_x --x position
	_p.y=_y --y position
	_p.dx=_dx --x speed
	_p.dy=_dy --y speed
	_p.type=_type --type
	_p.col=0 --color and sprite
	_p.s=_s --size

	--other variables
	_p.maxage=_maxage
	_p.age=0
	_p.rot=flr(rnd(4))
	_p.rot_timer=flr(rnd(6))
	_p.rot_delay=6+flr(rnd(6)) 
	_p.colarr=_col
	_p.os=_s
	
	--add particle to array
	add(part,_p)
end


function update_parts()
	local i=1
	while i<=#part do
		local _p=part[i]
		_p.age+=1
		--remove dead/offscreen particles
		if _p.age>_p.maxage
		or _p.x<-10 or _p.x>148
		or _p.y<-10 or _p.y>148 then
			--swap with last and pop
			part[i]=part[#part]
			part[#part]=nil
		else
			--change colors
			if #_p.colarr==1 then
				_p.col=_p.colarr[1]
			else
				local _ci=_p.age/_p.maxage  
				_ci=1+flr(_ci*#_p.colarr)
				_p.col=_p.colarr[_ci]
			end
			--apply gravity
			if _p.type==1 or _p.type==3 then
				_p.dy+=0.075
			end
			--chunks 
			if _p.type==3 then
				--settling
				if _p.age > _p.maxage*0.7 then
					_p.dx *= 0.9
					_p.dy *= 0.9
				end
				--rotation
				_p.rot_timer+=1
				if _p.rot_timer>_p.rot_delay then
					_p.rot+=1
					_p.rot_timer=0
					if _p.rot>=4 then
					_p.rot=0
					end
				end
			end
			--shrink
			if _p.type==2 or _p.type==4 then
				local _ci=1-(_p.age/_p.maxage)
				_p.s=_ci*_p.os
			end
			--friction
			if _p.type==2 or _p.type==4 then
				_p.dx/=1.2
				_p.dy/=1.2
			end
			--move particles
			_p.x+=_p.dx
			_p.y+=_p.dy
			--only increment if we didn't swap
			i+=1
		end
	end
end


function draw_parts()
	for i=1,#part do
		local _p=part[i]
		--pixel particle
		if _p.type==0 or _p.type==1 then
			pset(_p.x,_p.y,_p.col)
		--circle particle
		elseif _p.type==2 then
			circfill(_p.x,_p.y,_p.s,_p.col)
		--chunk particle
		elseif _p.type==3 then
			local _fx,_fy
			if _p.rot==2 then
				_fx=false
				_fy=true
			elseif _p.rot==3 then
				_fx=true
				_fy=true
			elseif _p.rot==4 then
				_fx=true
				_fy=false
			else
				_fx=false
				_fy=false
			end
			spr(_p.col,_p.x,_p.y,1,1,_fx,_fy)
			--line particle
		elseif _p.type==4 then
			line(_p.x,_p.y,_p.x+_p.s*sgn(_p.dx),_p.y,_p.col)
		end
	end
end


function spawn_trail(_x,_y)
	if rnd()<0.4 then 
		local _ang=rnd()
		local _ox=sin(_ang)*0.3
		local _oy=cos(_ang)*0.3
		local _mycol=timer_megaball>0 and col_mega or chain>=8 and col_fire or col_basic
		add_part(_x+_ox,_y+_oy,0,0,
			0, --type
			10+rnd(16), --life
			_mycol, --color         
			0) --size
	end
end


function shatter_block(_b,_vx,_vy)
	sfx(15)
	_b.dx=_vx*2
	_b.dy=_vy*2
	if shake<0.1 then 
		shake+=0.06
	end
	
	--max particles check
	local max_parts=500
	local parts_left=max_parts-#part
	if parts_left<=0 then return end
	
	--pixel shatter
	local dots=mid(0,15+flr(rnd(20)),parts_left)
	for i=1,dots do
		local _ang=rnd()
		local _dx=sin(_ang)*rnd(1.5)+(_vx/0.8)
		local _dy=cos(_ang)*rnd(1.5)+(_vy/0.8)
		add_part(
			_b.x+rnd(block_w),--x
			_b.y+rnd(block_h),--y
			_dx,_dy, --speed
			1, --type
			15+rnd(25), --life
			col_basic, --color
			0) --size
	end
	
	--chunk shatter
	parts_left=max_parts-#part
	local chunks=mid(0,2+flr(rnd(3)),parts_left)
	for i=1,chunks do
		local _ang=rnd()
		local _dx=sin(_ang)*rnd(1)+(_vx/0.8)
		local _dy=cos(_ang)*rnd(1)+(_vy/0.8)
		local _spr=16+flr(rnd(9))
		add_part(
			_b.x+rnd(block_w),--x
			_b.y+rnd(block_h),--y
			_dx,_dy, --speed
			3, --type
			45+rnd(35), --life
			{_spr}, --sprite number
			0) --size
	end
end


function puff_pill(_x,_y,_p)
	--pill colors by type
	--1=slowtime,2=life,3=sticky,4=expand,5=reduce,6=megaball,7=multiball,8=super laser
	local pill_cols={
		{9,9,2,0},{8,8,2,0},{11,3,3,0},{12,12,1,0},
		{13,13,1,0},{14,14,2,0},{2,2,1,0},{4,4,1,0}
	}
	for i=0,20 do
		local speed_mult=0.5+rnd(2)
		local _ang=rnd()
		local _dx=sin(_ang)*speed_mult
		local _dy=cos(_ang)*speed_mult
		local _mycol=pill_cols[_p] or pill_cols[8]
		--add puff
		add_part(
			_x,--x
			_y,--y
			_dx,_dy, --speed
			2, --type
			25+rnd(35), --life
			_mycol, --color
			1+rnd(4)) --size
	end
end


function puff_smoke(_x,_y)
	for i=0,8  do
		local speed_mult=0.5+rnd(1)
		local _ang=rnd()
		local _dx=sin(_ang)*speed_mult
		local _dy=cos(_ang)*speed_mult
		local _mycol=timer_megaball>0 and col_mega or chain>=8 and col_fire or col_basic
		add_part(
			_x,--x
			_y,--y
			_dx,_dy, --speed
			2, --type
			10+rnd(15), --life
			_mycol, --color
			1+rnd(2)) --size
	end
end


function spawn_death(_x,_y)
	for i=0,30 do
		local speed_mult=2+rnd(3)
		local _ang=rnd()
		local _dx=sin(_ang)*speed_mult
		local _dy=cos(_ang)*speed_mult
		local _mycol=chain>=8 and col_fire or {7,6,15,0}
		add_part(
			_x,--x
			_y,--y
			_dx,_dy, --speed
			2, --type
			50+rnd(35), --life
			_mycol, --color
			2+rnd(3)) --size
	end
end


function spawn_explosion(_x,_y)
	--first smoke
	for i=0,20 do
		local speed_mult=rnd(4)
		local _ang=rnd()
		local _dx=sin(_ang)*speed_mult
		local _dy=cos(_ang)*speed_mult
		add_part(
			_x,--x
			_y,--y
			_dx,_dy, --speed
			2, --type
			35+rnd(25), --life
			col_smoke, --color
			1+rnd(4)) --size
	end
			
	--fireball
	for i=0,35 do
		local speed_mult=1+rnd(3)
		local _ang=rnd()
		local _dx=sin(_ang)*speed_mult
		local _dy=cos(_ang)*speed_mult
		add_part(
			_x,--x
			_y,--y
			_dx,_dy, --speed
			2, --type
			20+rnd(25), --life
			col_fire, --color
			2+rnd(4)) --size
	end
end

function laser_puff(_x,_y,_super,_ready)
	if _super then
		--super laser
		for i=0,17 do
			local speed_mult=0.3+rnd(2)
			local _ang=rnd()
			local _dx=sin(_ang)*speed_mult
			local _dy=cos(_ang)*speed_mult-1
			
			add_part(_x,_y,_dx,_dy,
			2, --type
			10+rnd(15), --life
			col_laser, --color
			1+rnd(3)) --size
		end
		
	--laser cooldown ready
	elseif _ready then
		local half_w=pad_w/2
		local left_x=_x-half_w+2
		local right_x=_x+half_w-2
		--left pulse
		for i=0,6 do
			local _dx=pad_dx
			local _dy=1+pad_dy
			add_part(
				left_x,(_y-5),
				_dx,_dy,
				2,
				14,
				{2,8,8},
				1)
		end
		--right pulse
		for i=0,6 do
			local _dx=pad_dx
			local _dy=1+pad_dy
			add_part(
				right_x-2,(_y-5),
				_dx,_dy,
				2,
				14,
				{2,8,8},
				1)
		end
	else
	--normal laser
	local half_w=pad_w/2
	local left_x=_x-half_w+2
	local right_x=_x+half_w-2
	for side=0,1 do
		local px = side==0 and left_x or right_x
		for i=0,10 do
			local a=rnd()
			local speed=1.2+rnd(0.8)
			add_part(
				px,_y,
				sin(a)*speed,
				cos(a)*speed-0.4,
				2,              
				8+rnd(8),      
				col_laser,     
				1.1+rnd(0.6)
				) 
			end
		end
	end
end


function logo_parts()
	if rnd()<0.6 then 
		local zones={{36,10,30,15,15},{42,9,45,4,8},{67,5,40,4,12}}
		local z=zones[flr(rnd(3))+1]
		add_part(z[1]+rnd(z[2]),z[3]+rnd(z[4]),-1.5-rnd(1.5),rnd(0.4)-0.2,0,5+rnd(5),{z[5],z[5]>10 and 6 or 2},0)
	end
end

function spawn_speedlines(_x,_y,_dir)
	if rnd()<0.2 then 
		local _ox
		if _dir>0 then
			_ox=rnd()*2 --spawn on left edge
		else
			_ox=pad_w-2+rnd()*2 --spawn on right edge
		end
		local _oy=rnd()*pad_h
		local _mycol={6,13}
		
		add_part(_x+_ox,_y+_oy,
			_dir*-0.2, --move opposite to pad
			0, --no vertical move
			4, --line type
			6+rnd(8), --life
			_mycol,        
			1+rnd(3)) --line size
	end
end
-->8
--high score


function draw_score_panel(_x,_y,title,title_off,stats)
	local names={"level","score","broken blocks","power ups","paddle hits","laser shots","victories"}
	rectfill(_x,_y-5,128,_y+3,0)
	print(title,_x+title_off,_y-3,7)
	for i=1,#stats do
		print(names[i],_x+21,_y+7*i,7)
		local _points=" "..stats[i]
		print(_points,(_x+107)-(#_points*4),_y+7*i,7)
	end
end


function draw_hs(_x,_y)
	draw_score_panel(_x,_y,"high scores",44,hs)
end


function draw_stats(_x,_y)
	draw_score_panel(_x,_y,"your score",46,{stat_level,score,stat_blocks,stat_powers,stat_pad_hits,stat_laser_shots})
end


function reset_hs()
	--create default values
	hs={0,0,0,0,0,0,0}
	save_hs()
end


function load_hs()
	if dget(0)==1 then
		for i=1,7 do
			hs[i]=dget(i)
		end
	else
		reset_hs()
	end
end


function save_hs()
	dset(0,1)
	for i=1,7 do
		dset(i,hs[i])
	end
end


function check_hs()
	local stats={stat_level,score,stat_blocks,stat_powers,stat_pad_hits,stat_laser_shots}
	for i=1,6 do
		if stats[i]>hs[i] then
			hs[i]=stats[i]
		end
	end
	hs[7]+=stat_victories --cumulative victories
	save_hs()
end
-->8
--juicy stuff--


function do_shake()
	if shake>0 then
		--from -16 to +16
		local shakex=(16-rnd(32))*shake
		local shakey=(16-rnd(32))*shake
		camera(shakex,shakey)
		shake*=0.95
		if shake<0.05 then shake=0 end
	else
		--reset camera
		camera(0,0)
	end
end


function do_blink()
	local g_seq={7,6,0,0,5,5,5,5,0,0,6}
	local g_seq_fast={7,5,0,5}
	local normal_speed=3
	local fast_speed=1
	local flash_duration=45

	-- only trigger in menu modes
	local in_menu=(mode=="start" or mode=="game_over" or mode=="level_over" or mode=="winner")

	-- detect button press, start flash timer
	if in_menu then
		if btnp(5) then blink_x_flash=flash_duration end
		if btnp(4) then blink_z_flash=flash_duration end
	end

	-- shared blink timing (always update)
	blink_x_frame+=1
	if blink_x_frame>normal_speed then
		blink_x_frame=0
		blink_x_i+=1
		if blink_x_i>#g_seq then blink_x_i=1 end
	end

	-- x button blink
	if blink_x_flash>0 then
		blink_z_frame+=1
		if blink_z_frame>fast_speed then
			blink_z_frame=0
			blink_z_i+=1
			if blink_z_i>#g_seq_fast then blink_z_i=1 end
		end
		blink_x_g=g_seq_fast[blink_z_i]
		blink_x_flash-=1
	else
		blink_x_g=g_seq[blink_x_i]
	end

	-- z button blink
	if blink_z_flash>0 then
		blink_z_frame+=1
		if blink_z_frame>fast_speed then
			blink_z_frame=0
			blink_z_i+=1
			if blink_z_i>#g_seq_fast then blink_z_i=1 end
		end
		blink_z_g=g_seq_fast[blink_z_i]
		blink_z_flash-=1
	else
		blink_z_g=g_seq[blink_x_i]
	end
	-- dim the other text when one is flashing
	if mode=="game_over" then
		if blink_x_flash>0 then 
			blink_z_g=0 
		end
		if blink_z_flash>0 then 
			blink_x_g=0 
		end
	end
end


function arrow_blink()
	arr_b_frame+=1
	arr_b=1+abs(sin(arr_b_frame/60))*0.5 --slow pulse from 1 to 1.5
end



function fade_screen(_f)
	local fade_table={
		[0]=0,[1]=0,[2]=1,[3]=1,[4]=2,[5]=1,[6]=13,[7]=6,
		[8]=2,[9]=4,[10]=9,[11]=3,[12]=1,[13]=1,[14]=2}
	local steps = flr(mid(0,_f,1)*4)
	palt(0,false)
	-- fade colors 0..14
	for i=0,14 do
		local c=i
		for s=1,steps do
			c=fade_table[c]
		end
		pal(i,c,1)
	end
	-- fade color 15 through dark gray -> black
	pal(15,steps>=2 and 0 or 5,1)
end

-->8
--sfx and music

--sfx(0) ball hits pad 
--sfx(chain) chain sound (1-8)
--sfx(9) speed down power
--sfx(10) life +1 
--sfx(11) ball hits wall
--sfx(12) hit indestructible block
--sfx(13) pick up power up
--sfx(14) laser shot
--sfx(15) block shatter
--sfx(16) paddle jump
--sfx(17) laser cooldown back
--sfx(18) sticky
--sfx(19) loose live
--sfx(20) start and game over button
--sfx(20) press z
--sfx(21) super laser shot
--sfx(22) explosion sound
--sfx(23) press x 
--sfx(24) no laser available
--sfx(25) finished level
--sfx(26) new level
--sfx(27) winner jingle
--sfx(28) sudden death

--music() start menu music
	--starting from sfx(32) 




__gfx__
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000bbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbb00000000000000000000000000000000000000000000000000000000
00700700bb0990bbbb0880bbbb0330bbbb0cc0bbbb0dd0bbbb0ee0bbbb0220bbbb0440bb00000000000000000000000000000000000000000000000000000000
00077000b097990bb087880bb037330bb0c7cc0bb0d7dd0bb0e7ee0bb027220bb047440b00000000000000000000000000000000000000000000000000000000
00077000b099990bb088880bb033330bb0cccc0bb0dddd0bb0eeee0bb022220bb044440b00000000000000000000000000000000000000000000000000000000
00700700bb0990bbbb0880bbbb0330bbbb0cc0bbbb0dd0bbbb0ee0bbbb0220bbbb0440bb00000000000000000000000000000000000000000000000000000000
00000000bbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbb00000000000000000000000000000000000000000000000000000000
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000600000660000000600000006060000000000000000000000000000000000000000000000000000000000
00006000006660000000660000666000006606000066600000666000006666000066660000000000000000000000000000000000000000000000000000000000
00066000000600000006660000666600006666000006600000600000006660000006660000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeee0000000000eee000ee3e33333e3eeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
e66767776766eeee006660000e222e00e66767776766eeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
e6d6d666d6d60eee06766600e27222e0e6d6d666d6d60eee00000000000000000000000000000000000000000000000000000000000000000000000000000000
e6d6d666d6d60eee0666d600e22252e0e6d6d666d6d60eee00000000000000000000000000000000000000000000000000000000000000000000000000000000
ee00000000000eee06ddd600e25552e0ee00000000000eee00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeee006660000e222e00eeeeeeeeeeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeee0000000000eee000eeeeeeeeeeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeee0000000000000000eeeeeeeeeeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
666eee666e0000000000666eee666efffffffffe666666666ebbbbbbbbbeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000
660e8ee6600000000000660ccee660fffffffff06666666660bbbbbbbbb0eeeeeeeeee0000000000000000000000000000000000000000000000000000000000
66ee9ee660000000000066eecce660fffffffff06666666660bbbbbbbbb0eeeeeeeeee0000000000000000000000000000000000000000000000000000000000
6660ee666000000000006660ee6660fffffffff06666666660bbbbbbbbb0eeeeeeeeee0000000000000000000000000000000000000000000000000000000000
e000eee0000000000000e000eee000e000000000e000000000e000000000eeeeeeeeee0000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeee0000eeeeeeeeeeeeeeeeeeeeee0eeee00ee00ee00ee00eeeeeeeeeeeeeeeeee000e0e0e000e000ee
eeeeeeeeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeee066660eeeeeeeeeeeeeeeeeeee080ee0880088008800880eeeeeeeeeeeeeeee0ccc0c0c0ccc0ccc0e
eeeeeeeeeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeee06666660eeeeeeeeeeeeeeeeeee080e08080800080008080eeeeeeeeeeeeeeee00c00c0c0ccc0c0c0e
eeeeeeeeeeeeeeeeeeeeee77eeeeeeeeeeeeeeeeeeeee0667666760eeeeee0e00e0e0e00e080e0888088808800880eeeeeeeeeeeeeeee0c0c00c0c0c0c0ccc0e
eeeeeeeeeeeeeeeeeeeeeee777eeeeeeeeeeeeeeeeeee0667666760eeeeeeeeeeeeeeeeee080008080008080008080eeeeeeeeeeeeeee0ccc00ccc0c0c0c00ee
eeeeeeeeeeeeeeeeeeeeeeee767eeeeeeeeeeeeeeeeee0666667760eeeeeeeeeeeeeeeeee088808080880088808080eeeeeeeeeeeeeeee000ee000e0e0e0eeee
eeeeeeeeeeeeeeeeeeeeeeee7777eeee7eeeeeeeee7ee0666677760eeeeeee0e00e0e000ee000e0e0e00ee000e0e0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeee767eeeeee7eee7eeeeee06777760eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eee0eee0eee0eeeee
eeeeeeeeeeeeeeeeeeeeeeeeeee777eeeeeeeeeeeeee7ee066660eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eee0eee0eee0eeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeee767ee7eeee7ee7ee77ee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeee777eee77eeeeee7777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeee7eeee767ee777ee7ee776777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777ee777e7ee77777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeee7eee767ee77eee77677eeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee767eeeeee7777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeee77e7ee7ee7677ee7e767eee77eeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeee77eeeeeeee77e7eee77ee7e77eeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeee77eeeeeee777eeeee77ee7eeeeeeeee7eee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeee7ee7e777eeee7777eeee777eeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeee77eeeeeeeeeeeeeeeeee777777ee777ee7ee77e000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeee777777eeeeee77777777777eeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
00000ee00000ee00000eee000ee000e000ee000ee000e00e00000000000000000000000000000000000000000000000000000000000000000000000000000000
077770e077770e077770e07770e0770770e07770e077077007777770000000000000000000000000000000000000000000000000000000000000000000000000
0fffff00fffff00ffff00fffff00ff0ff00fffff00ff0ff00ffffff0000000000000000000000000000000000000000000000000000000000000000000000000
0ff0ff00ff0ff00ff00e0ff0ff00ff0ff00ff0ff00ff0ff0000ff000000000000000000000000000000000000000000000000000000000000000000000000000
066660e066666006660e0666660066660e06606600660660ee0660ee000000000000000000000000000000000000000000000000000000000000000000000000
0666660066660e06660e0666660066660e06606600660660ee0660ee000000000000000000000000000000000000000000000000000000000000000000000000
0770770077077007700e0770770077077007707700770770ee0770ee000000000000000000000000000000000000000000000000000000000000000000000000
077777007707700777700770770077077007777700777770ee0770ee000000000000000000000000000000000000000000000000000000000000000000000000
077770e077077007777007707700770770e07770ee07770eee0770ee000000000000000000000000000000000000000000000000000000000000000000000000
00000ee000e00000000e000e000000e000ee000eeee000eeee0000ee000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
30020000057670c7770c7770c777117670c7070c7071f7071d7071b707187071670713707117070f7072b7072b707307073370735707357073370730707307072e7072b70727707227071d7071b7071b7071b707
1801000013537165471654716507185070c5070c5071f5071d5071b507185071650713507115070f5072b5072b507305073350735507355073350730507305072e5072b50727507225071d5071b5071b5071b507
18010000155371854718547185071a5070c5070c5071f5071d5071b507185071650713507115070f5072b5072b507305073350735507355073350730507305072e5072b50727507225071d5071b5071b5071b507
18010000175371a5471a5471a5071c5070c5070c5071f5071d5071b507185071650713507115070f5072b5072b507305073350735507355073350730507305072e5072b50727507225071d5071b5071b5071b507
18010000185371b5471b5471b5071d5070c5070c5071f5071d5071b507185071650713507115070f5072b5072b507305073350735507355073350730507305072e5072b50727507225071d5071b5071b5071b507
180100001a5471d5571d5571c5071f5070c5070c5071f5071d5071b507185071650713507115070f5072b5072b507305073350735507355073350730507305072e5072b50727507225071d5071b5071b5071b507
180100001c5471f5571f5571e507205070c5070c5071f5071d5071b507185071650713507115070f5072b5072b507305073350735507355073350730507305072e5072b50727507225071d5071b5071b5071b507
180100001d547205572055720507235070c5070c5071f5071d5071b507185071650713507115070f5072b5072b507305073350735507355073350730507305072e5072b50727507225071d5071b5071b5071b507
180100001f557225672256722777245070c5070c5071f5071d5071b507185071650713507115070f5072b5072b507305073350735507355073350730507305072e5072b50727507225071d5071b5071b5071b507
79050000220651e05519055140450f0350a03506025030251b0651606514055120450f0350a035080250602503025010250102535005100053300530005300052e0052b00527005220051d0051b0051b0051b005
63060000200251b02519035160351b04520055250552c0453305531005330053300522005270052a0053300506005180053300535005100053300530005300052e0052b00527005220051d0051b0051b0051b005
300200000c7670f7770f7770f7770f7670f7070c7071f7071d7071b707187071670713707117070f7072b7072b707307073370735707357073370730707307072e7072b70727707227071d7071b7071b7071b707
600100003c5373f5473f54723507265070c5070c5071f5071d5071b507185071650713507115070f5072b5072b507305073350735507355073350730507305072e5072b50727507225071d5071b5071b5071b507
b00100002d0172d0272d0272d0373904739047390373902737727377173771737714377153300724007240072400724007270072a0072a0072a0072a0072a0072a0072a0072a0072a0072a007000070000700007
66010000397303874037750357603376032750307402e7402b730297302772025720227101f7101d7001a70018700167001570000700007000070000700007000070000700007000070000700007000070000700
970300003a642336422b63227632226241f6251b614186151661413615116140d6150f6040c6050a6040760520605276050e6051a605216050460508605036050160500605036050060501605016050060500000
680100001a0771c0671f0572104723037230272302723027230172301700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007
b0020000075110751207511075220753107532075310754207541075420a5510c5521155111552115511155205552055421653216522165221651216502075002b5012b501035010350103501035010050100001
b001000003613076110c621116311565117661196711b6711b6721867214672116620c64205632016220061200600006000060000600006000060000600006000060000600006000060000600006000060000600
8803000005132051320513205132051220512207122071120a1120a1220a1320a1420a1420a1520a1620a1620a1620a1620a16200162001520015200132001320012200102071020710200102001020010200102
280300001807018070130601305018040180300e0300e040070400703007030000001f0001f0001f0001f0001f0001f0003a0003a0003a0002100024000240002400018000240002400024000240002400024000
660100003573033740307302e7202b720297202772024720227101f7101d7101b7101871016710137101171003710037100371003710037100371003710037100371003710037100370003700037000370003700
480300003767331673226511f6511d641116410f6510e6430d6420c6320b6220b6120a62409625086240762507624036150161401615016140161501614016150060200602006020060200602006020060200602
2903000018070180701306013050180401803013030130401804018030180301f0001f0001f0001f0001f0001f0001f0003a0003a0003a0002100024000240002400018000240002400024000240002400024000
500500000332007300033200330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5008000030525305152c5352c515295252951524535245151d5351d51529500295001b5051b5052e5051d500005000050020505205052c5052c505005000050020500205002c5002c50020500205002050020502
6a0800001d5351d515245352451529525295152c5352c5153052530515295002950024500245001d5001d50000500005001b5001b5002e5002e50030500305002c5002c500295002950024500245001d5001d500
5008000030525305152c5352c515295252951524535245151d5351d51529500295001b5251b5152e5151d500005000050020525205152c5252c515005000050020500205002c5002c50020500205002050020502
d30a00003051230502305022c5022c50220502205021350216502185021b5022e5022e50233502335022550225502275022750200502005020e5021b5022e5022e5022c5022c50220502205022c5022c50200000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a51100000015300000306230000030623000000034300000001530000030623000000034300000000000000000153000003062300000003430000000000000000015300000306230000030623000001863200000
a51100000015300000306230000030623000000034300000001530000030623000000034300000000000000000153000003062300000003430000000000000000015300000306230000030623000001863200000
5d1100000015300000000000000030623000000000000000003430000000000000003062300000001530000000153000000000000000186320000000000000000034300000000000000000153000000000000000
a51100000015300000306230000030623000000034300000001530000030623000000034300000000000000000153000003062300000003430000000000000000015300000306230000030623000001863200000
77110000183211831100000000000000000000013310131100000000000000000000000000000000000000000000000000000000000000000000000000000000200122001200321003110c3310c3112901229012
41110000000000000000000000002e3112e301000000000000000000000000000000000000000000000000002b3112b3010000000000293212931120321203111d3211d311243212431130321303112c0122c012
771100000c3210c3111833118311000000000005331053110000000000000000000003331033112b0122b01218012180121801218012113211131120321203111b3211b311003210031100321003110033100311
4111000000000000002532125311223212231125321253111f3211f31100000000002e0122e0122c3212c3111f3211f3112732127311000000000029321293110000000000000000000030331303113032130311
7711000000331003110000000000000000000000000000000000000000000000000001321013110133101311000000000011321113110a3210a3110d3310d3110733107311083310831100331003110033100311
4111000018331183112932129311000000000000000000001d3211d31100000000002201222012313313131100000000002e3212e311293212931100000000001832118311000000000000000000000000000000
77110000240022400200321003111d3311d31100000000002c0122c0121d3211d3112900229002290022900203331033110d3310d311003210031118321183110000000000000000000000000000000000000000
4111000030321303112b3212b311000000000018321183112e3212e31119321193112c0022c0022c3112c30131321313111d3211d3111d3211d3111d3111d3011f3211f3112c3212c31118321183112432124311
7711000000321003111632116311000000000000000000001132111311000000000022331223111b0121b01200000000002033120311193211931118022180221433114311073210731100000000000033100311
4111000000000000001d3211d31129321293112932129311303213031127311273011f0121f0122e3112e301253112530100000000001d3211d311313213131122331223111b3211b31130321303113033130311
771100000000000000073210731100000000001933119311183211831118321183110f3210f311013210131100331003110000000000013310131103331033112c0222c0220c3210c31100000000000000000000
411100002432124311000000000025321253112e3212e311000000000022321223110000000000000000000027321273110000000000200022000220002200021832118311243212431100000000000000000000
__music__
01 20232440
00 20232440
00 20232440
00 23242540
00 20232440
00 20232440
00 20232440
00 23242540
00 22272840
00 22272840
00 22272840
00 23282940
00 22272840
00 22272840
00 22272840
00 23282940
00 21232440
00 21242540
00 21232440
00 23242540
00 22272840
00 22272840
00 22272840
00 23282940
00 22272840
00 22272840
00 22272840
02 23282940

