--!strict
-- Colours and fonts for the HUD, in Roblox's chunky house style kept dark for a night
-- shift: thick near-black outlines, rounded corners, hard drop shadows, saturated
-- buttons (Roblox's own play-button green for BOARD), white bold type with a dark
-- stroke. Ticket paper and the rubber stamps keep their printed look.

local Theme = {
	Colors = {
		ink = Color3.fromRGB(12, 15, 20),
		outline = Color3.fromRGB(8, 10, 14), -- thick outlines round panels and buttons
		shadow = Color3.fromRGB(4, 6, 9), -- hard drop shadows under panels
		panel = Color3.fromRGB(26, 32, 43),
		panelLight = Color3.fromRGB(44, 53, 68),
		line = Color3.fromRGB(70, 82, 100),
		text = Color3.fromRGB(255, 255, 255),
		muted = Color3.fromRGB(176, 186, 200),
		lamp = Color3.fromRGB(255, 196, 84),
		lampDeep = Color3.fromRGB(214, 128, 30),
		paper = Color3.fromRGB(238, 230, 206),
		paperShade = Color3.fromRGB(212, 201, 172),
		paperInk = Color3.fromRGB(44, 40, 34),
		paperMuted = Color3.fromRGB(120, 110, 92),
		stampRed = Color3.fromRGB(186, 38, 36),
		stampBlue = Color3.fromRGB(46, 82, 150),
		board = Color3.fromRGB(0, 176, 111),
		boardDeep = Color3.fromRGB(0, 112, 70),
		deny = Color3.fromRGB(232, 62, 52),
		denyDeep = Color3.fromRGB(150, 28, 24),
		good = Color3.fromRGB(80, 220, 140),
		bad = Color3.fromRGB(255, 92, 80),
		radio = Color3.fromRGB(150, 226, 186),
	},
	Fonts = {
		display = Font.fromEnum(Enum.Font.FredokaOne), -- big titles: the round-cornered Roblox game font
		title = Font.fromEnum(Enum.Font.BuilderSansExtraBold), -- buttons, status, captions: Roblox's own
		body = Font.fromEnum(Enum.Font.BuilderSansMedium),
		bodyBold = Font.fromEnum(Enum.Font.BuilderSansBold),
		ticket = Font.fromEnum(Enum.Font.SpecialElite), -- typed on the ticket and the ledger
		print = Font.fromEnum(Enum.Font.Oswald), -- printed on the ticket, and the rubber stamps
	},
	-- The HUD is laid out on a canvas at least this size, then scaled to the screen.
	-- Phones in landscape land between about 0.7 (iPhone SE) and 0.8, which keeps the
	-- 64 px buttons at or above the 44 px minimum touch target.
	DesignWidth = 960,
	DesignHeight = 420,
	MinScale = 0.66,
	MaxScale = 1.4,
}

return Theme
