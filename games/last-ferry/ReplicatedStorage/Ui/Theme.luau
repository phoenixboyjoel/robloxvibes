--!strict
-- Colours and fonts for the HUD. Night harbor: cold blue panels, warm lamp
-- accents, ticket paper, and red kept for the rubber stamp and Mara.

local Theme = {
	Colors = {
		ink = Color3.fromRGB(12, 15, 20),
		panel = Color3.fromRGB(20, 25, 32),
		panelLight = Color3.fromRGB(32, 39, 49),
		line = Color3.fromRGB(62, 72, 86),
		text = Color3.fromRGB(234, 236, 240),
		muted = Color3.fromRGB(150, 160, 174),
		lamp = Color3.fromRGB(255, 198, 132),
		paper = Color3.fromRGB(238, 230, 206),
		paperShade = Color3.fromRGB(212, 201, 172),
		paperInk = Color3.fromRGB(44, 40, 34),
		paperMuted = Color3.fromRGB(120, 110, 92),
		stampRed = Color3.fromRGB(186, 38, 36),
		stampBlue = Color3.fromRGB(46, 82, 150),
		board = Color3.fromRGB(58, 122, 88),
		deny = Color3.fromRGB(150, 54, 48),
		good = Color3.fromRGB(128, 206, 150),
		bad = Color3.fromRGB(240, 110, 98),
		radio = Color3.fromRGB(170, 214, 190),
	},
	Fonts = {
		title = Font.fromEnum(Enum.Font.Oswald),
		body = Font.fromEnum(Enum.Font.BuilderSans),
		bodyBold = Font.fromEnum(Enum.Font.BuilderSansBold),
		ticket = Font.fromEnum(Enum.Font.SpecialElite),
		speech = Font.fromEnum(Enum.Font.Merriweather),
		mono = Font.fromEnum(Enum.Font.RobotoMono),
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
