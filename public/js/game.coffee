
# CONSTANTS
PROFILE_WIDTH = 250
PROFILE_CARD_GAP = 10
CARD_WIDTH = 71
CARD_HEIGHT = 96
CARD_OVERLAP = 24
DEALING_SPEED_FAST = 40
DEALING_SPEED_SLOW = 300
PLAYER_LOCATION =
	5: [
		{ side: "bottom", location: 0.5 }
		{ side: "left", location: 0.6 }
		{ side: "top", location: 0.25 }
		{ side: "top", location: 0.75 }
		{ side: "right", location: 0.6 }
	]

# UTILITIES
floor = Math.floor
assert = (conditional, message = "") ->
	if not conditional
		console.log(message)
		alert(message)

# MODELS
class Card
	constructor: (@playing_field, @face, @direction, x, y) ->
		# 카드 엘레멘트 생성
		@elem = $("#card_template")
			.clone()
			.addClass(@face)
			.addClass(@direction)
			.appendTo(@playing_field.elem)

		size = @getSize()
		@elem.css("left", (x - floor(size.width / 2)) + "px")
			.css("top", (y - floor(size.height / 2)) + "px")

		@playing_field.addCard(this)

	getSize: ->
		if @direction == "vertical"
			{width: CARD_WIDTH, height: CARD_HEIGHT}
		else
			{width: CARD_HEIGHT, height: CARD_WIDTH}

	moveTo: (cx, cy, duration) ->
		sz = @getSize()
		left = cx - floor(sz.width / 2)
		top = cy - floor(sz.height / 2)
		@elem.animate({left: left, top: top}, duration)

	setFace: (face) ->
		@elem.removeClass(@face).addClass(face)
		@face = face

	setDirection: (direction) ->
		@elem.removeClass(@direction).addClass(direction)
		@direction = direction

	remove: ->
		@elem.remove()
		null

class PlayingField
	constructor: (@elem) ->
		@cards = []
		@players = []

	getCardDirection: (player) ->
		side = PLAYER_LOCATION[@players.length][player].side
		if side in ["top", "bottom"] then "vertical" else "horizontal"

	# 플레이어 x가 y장 카드를 가지고 있을 때, z번 카드의 가운데 위치는?
	getCardPosition: (player, cards, index) ->
		{side: side, location: location} = PLAYER_LOCATION[@players.length][player]
		# 깔끔하게 구현하고 싶지만.. -_-
		dx = dy = 0
		if side in ["top", "bottom"]
			cx = @convertRelativePosition(location, 0).x
			if side == "top"
				cy = CARD_HEIGHT / 2
				dx = -1
			else
				cy = @getSize().height - CARD_HEIGHT / 2
				dx = 1
		else
			cy = @convertRelativePosition(0, location).y
			if side == "left"
				cx = CARD_HEIGHT / 2
				dy = 1
			else
				cx = @getSize().width - CARD_HEIGHT / 2
				dy = -1
		totalWidth = CARD_WIDTH + (cards - 1) * CARD_OVERLAP
		fx = cx + dx * (floor(totalWidth / 2) - CARD_WIDTH / 2)
		fy = cy + dy * (floor(totalWidth / 2) - CARD_WIDTH / 2)
		{x: floor(fx - dx * CARD_OVERLAP * index), y: floor(fy - dy * CARD_OVERLAP * index)}

	getProfilePosition: (player) ->
		{side: side, location: location} = PLAYER_LOCATION[@players.length][player]
		# 깔끔하게 구현하고 싶지만.. -_-
		width = if side in ["top", "bottom"] then 254 else 200
		height = if side in ["top", "bottom"] then 50 else 104
		if side in ["top", "bottom"]
			return {
				side: side,
				x: @convertRelativePosition(location, 0).x - width / 2,
				y: if side == "top" then CARD_HEIGHT + PROFILE_CARD_GAP else @getSize().height - CARD_HEIGHT - PROFILE_CARD_GAP - height
			}
		else
			return {
				side: side,
				y: @convertRelativePosition(0, location).y - height / 2,
				x: if side == "left" then CARD_HEIGHT + PROFILE_CARD_GAP else @getSize().width - CARD_HEIGHT - PROFILE_CARD_GAP - width
			}

	clearCards: ->
		@cards.pop().remove() while @cards.length > 0
		null

	getSize: ->
		{width: @elem.width(), height: @elem.height()}

	addCard: (card) ->
		@cards.push(card)

	convertRelativePosition: (x, y) ->
		sz = @getSize()
		{x: floor(sz.width * x), y: floor(sz.height * y)}

	# 각 플레이어의 카드가 주어질 때 셔플 애니메이션을 보여주고, hand[] 에 각 카드를 등록한다
	deal: (cards, startFrom, done=->) ->
		@clearCards()
		assert(cards.length == @players.length)
		@hands = ([] for i in [0..@players.length-1])
		center = @convertRelativePosition(0.5, 0.5)
		@cardStack = []
		for i in [0..52]
			card = new Card(this, "back", "vertical", center.x, center.y - floor(i / 4) * 2)
			card.elem.addClass("group" + (floor(i / 4) %2)).delay(i * 5).fadeIn(0)
			@cardStack.push(card)
		# 마지막 카드가 보여지고 나면 셔플 동작을 한다
		@cardStack[52].elem.promise().done(=>
			for i in [0..0]
				$(".group0")
					.animate({left: "-=37"}, 100)
					.animate({top: "-=2"}, 0)
					.animate({left: "+=74"}, 200)
					.animate({top: "+=2"}, 0)
					.animate({left: "-=37"}, 100)
				$(".group1")
					.animate({left: "+=37"}, 100)
					.animate({top: "+=2"}, 0)
					.animate({left: "-=74"}, 200)
					.animate({top: "-=2"}, 0)
					.animate({left: "+=37"}, 100)
			# 셔플을 다 하고 나면 카드를 돌린다
			$(".group1").promise().done(=>
				dealt = 0
				for index in [0..cards[0].length-1]
					for pl in [0..@players.length-1]
						player = (startFrom + pl) % @players.length
						card = @cardStack.pop()
						@hands[player].push(card)
						face = cards[player][index]
						do (card, face, player, index, dealt) =>
							setTimeout(
								=>
									card.setFace face
									card.setDirection @getCardDirection player
									pos = @getCardPosition(player, cards[0].length, index)
									card.moveTo(pos.x, pos.y, DEALING_SPEED_FAST)
									null
								, dealt * DEALING_SPEED_FAST)
						dealt++

				setTimeout(
					=>
						for i in [0..@cardStack.length-1]
							@cardStack[i].elem.animate({top: "-=#{i * 2}", left: "-=#{ i * 2 }"}, 50)
						null
					, dealt * DEALING_SPEED_FAST
				)
				setTimeout(done, dealt * DEALING_SPEED_FAST)
				null
			)
			null
		)
		null

	# cardStack 에 남은 카드들을 player 에게 준다.
	dealAdditionalCards: (faces, player) ->
		console.log(faces)
		n = faces.length
		assert(n == @cardStack.length)
		for idx in [0..n-1]
			card = @cardStack.pop()
			do (idx, card) =>
				console.log(idx)
				setTimeout(
					=>
						card.setFace(faces[idx])
						console.log("dealing", faces[idx], idx)
						card.setDirection @getCardDirection player
						@hands[player].push(card)
						for i in [0..@hands[player].length-1]
							pos = @getCardPosition(player, @hands[player].length, i)
							@hands[player][i].moveTo(pos.x, pos.y, DEALING_SPEED_SLOW)
						null
					, idx * DEALING_SPEED_SLOW
				)


		null

	playerMessage: (player, type, message) ->
		elem = @players[player].profile_elem
		if @players[player].fadeEventId
			clearTimeout(@players[player].fadeEventId)
			@players[player].fadeEventId = null
		elem.find("dd")
			.stop()
			.animate({"background-color": "rgba(255, 255, 255, 0.8)"}, 150)
			.animate({"background-color": "rgba(255, 255, 255, 0)"}, 4000)
		elem.find(".message_type").html(type)
		elem.find(".message_content").html(message)

	setPlayers: (players) ->
		@players = players
		for i in [0..@players.length-1]
			{side: side, y: y, x: x} = @getProfilePosition(i)
			elem = $("#profile_template")
				.clone()
				.addClass(side)
				.appendTo(@elem)
			elem.find(".picture").attr({src: @players[i].picture})
			elem.find(".name").html(@players[i].name)
			elem.css({left: x, top: y})
			elem.show()
			@players[i].profile_elem = elem


field = null

TEST_CARDS = [["s1", "h2", "ht", "h1", "h4", "sk", "s2", "s3", "s4", "c3"],
		 ["back", "back", "back", "back", "back", "back", "back", "back", "back", "back"],
 		 ["back", "back", "back", "back", "back", "back", "back", "back", "back", "back"],
 		 ["back", "back", "back", "back", "back", "back", "back", "back", "back", "back"],
		 ["back", "back", "back", "back", "back", "back", "back", "back", "back", "back"]]

$(document).ready(->
	window.field = new PlayingField $ "#playing_field"
	window.field.setPlayers([
		{name: "JongMan Koo", picture: "http://profile.ak.fbcdn.net/hprofile-ak-snc4/49218_593417379_9696_q.jpg"}
		{name: "Wonha Ryu", picture: "http://profile.ak.fbcdn.net/hprofile-ak-snc4/41489_100000758278961_2887_q.jpg"}
		{name: "Jinho Kim", picture: "http://profile.ak.fbcdn.net/hprofile-ak-snc4/161338_100000247121062_7309182_q.jpg"}
		{name: "DoKyoung Lee", picture: "http://profile.ak.fbcdn.net/hprofile-ak-snc4/273911_100001947905915_2944452_q.jpg"}
		{name: "Hyun-hwan Jung", picture: "http://profile.ak.fbcdn.net/hprofile-ak-snc4/202947_100002443708928_4531642_q.jpg"}
	])
	window.field.deal TEST_CARDS, 1, ->
		setTimeout(
			->
				window.field.playerMessage(1, "선거", "패스")
			, 100)
		setTimeout(
			->
				window.field.playerMessage(2, "공약", "다이아몬드 14")
			, 1100)
		setTimeout(
			->
				window.field.playerMessage(3, "공약", "클로버 15")
			, 2400)
		setTimeout(
			->
				window.field.playerMessage(4, "선거", "패스")
			, 4000)
		setTimeout(
			->
				window.field.playerMessage(0, "공약", "스페이드 16")
			, 6000)
		setTimeout(
			->
				window.field.playerMessage(2, "선거", "패스")
			, 6500)
		setTimeout(
			->
				window.field.playerMessage(3, "선거", "패스")
				window.field.playerMessage(0, "당선", "스페이드 16")
			, 7000)
		setTimeout(
			->
				window.field.dealAdditionalCards(["sq", "jr", "hk"], 0)
			, 8000)

)
