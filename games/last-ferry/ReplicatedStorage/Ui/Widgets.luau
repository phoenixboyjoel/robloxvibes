--!strict
-- Pieces the HUD and the overlay cards share: captions, wrapped paragraphs, rule rows
-- (a numbered badge each; new rules bold with a NEW tag), pills and lantern icons.

local View = require("../Shared/Types")
local Theme = require("./Theme")
local Ui = require("./Ui")

local C = Theme.Colors
local F = Theme.Fonts

local Widgets = {}

function Widgets.caption(parent: Instance, text: string, color: Color3, order: number): TextLabel
	return Ui.label(parent, "Caption", {
		text = text,
		font = F.title,
		size = 15,
		color = color,
		order = order,
	})
end

export type ParagraphProps = {
	font: Font?,
	size: number?,
	color: Color3?,
	order: number?,
	rich: boolean?,
	xAlign: Enum.TextXAlignment?,
}

-- A full-width label that wraps and grows to fit its text.
function Widgets.paragraph(parent: Instance, text: string, props: ParagraphProps?): TextLabel
	local p: ParagraphProps = props or {}
	return Ui.label(parent, "Paragraph", {
		text = text,
		font = p.font or F.body,
		size = p.size or 18,
		color = p.color or C.text,
		wrap = true,
		rich = p.rich,
		xAlign = p.xAlign,
		frameSize = UDim2.fromScale(1, 0),
		autoSize = Enum.AutomaticSize.Y,
		order = p.order or 0,
		lineHeight = 1.1,
	})
end

-- A small rounded tag: "NEW", "2/5" and the like.
function Widgets.tag(parent: Instance, name: string, text: string, fill: Color3, ink: Color3, size: number): TextLabel
	local tag = Ui.label(parent, name, {
		text = text,
		font = F.title,
		size = size,
		color = ink,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(0, size + 8),
		autoSize = Enum.AutomaticSize.X,
	})
	tag.BackgroundTransparency = 0
	tag.BackgroundColor3 = fill
	Ui.corner(tag, UDim.new(0.5, 0))
	Ui.stroke(tag, C.outline, 2)
	Ui.padding(tag, 0, 8, 0, 8)
	return tag
end

function Widgets.ruleRow(parent: Instance, index: number, rule: View.RuleLine, textSize: number)
	local row = Ui.frame(parent, "Rule", UDim2.fromScale(1, 0))
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.LayoutOrder = 10 + index
	-- The rule's number in a round badge, lamp-bright when it's new tonight.
	local badge = Ui.label(row, "Number", {
		text = tostring(index),
		font = F.title,
		size = textSize - 2,
		color = if rule.isNew then C.ink else C.text,
		xAlign = Enum.TextXAlignment.Center,
		frameSize = UDim2.fromOffset(textSize + 6, textSize + 6),
	})
	badge.BackgroundTransparency = 0
	badge.BackgroundColor3 = if rule.isNew then C.lamp else C.panelLight
	Ui.corner(badge, UDim.new(0.5, 0))
	Ui.stroke(badge, C.outline, 2)
	Ui.label(row, "Text", {
		text = rule.text,
		font = if rule.isNew then F.bodyBold else F.body,
		size = textSize,
		color = if rule.isNew then C.text else C.muted,
		wrap = true,
		frameSize = UDim2.new(1, if rule.isNew then -(textSize + 62) else -(textSize + 14), 0, 0),
		position = UDim2.fromOffset(textSize + 12, 1),
		autoSize = Enum.AutomaticSize.Y,
		lineHeight = 1.05,
	})
	if rule.isNew then
		local tag = Widgets.tag(row, "New", "NEW", C.lamp, C.ink, 12)
		tag.AnchorPoint = Vector2.new(1, 0)
		tag.Position = UDim2.new(1, 0, 0, 1)
	end
end

-- A lantern for the top bar: a cap, a glass that glows while lit, and a base. The frame
-- carries a "Lit" attribute.
function Widgets.lantern(parent: Instance, order: number): Frame
	local lantern = Ui.frame(parent, `Lantern{order}`, UDim2.fromOffset(24, 34))
	lantern.LayoutOrder = order
	local cap = Ui.frame(lantern, "Cap", UDim2.fromOffset(14, 6), UDim2.fromScale(0.5, 0), Vector2.new(0.5, 0))
	cap.BackgroundTransparency = 0
	cap.BackgroundColor3 = C.outline
	Ui.corner(cap, UDim.new(0, 2))
	local glass = Ui.frame(lantern, "Glass", UDim2.fromOffset(20, 22), UDim2.fromOffset(2, 6))
	glass.BackgroundTransparency = 0
	Ui.corner(glass, UDim.new(0, 6))
	Ui.stroke(glass, C.outline, 2.5)
	Ui.gloss(glass, 0.35)
	local base = Ui.frame(lantern, "Base", UDim2.fromOffset(20, 5), UDim2.new(0.5, 0, 1, -5), Vector2.new(0.5, 0))
	base.BackgroundTransparency = 0
	base.BackgroundColor3 = C.outline
	Ui.corner(base, UDim.new(0, 2))
	return lantern
end

function Widgets.setLantern(lantern: Frame, lit: boolean)
	lantern:SetAttribute("Lit", lit)
	local glass = lantern:FindFirstChild("Glass")
	if glass and glass:IsA("Frame") then
		glass.BackgroundColor3 = if lit then C.lamp else Color3.fromRGB(46, 50, 58)
	end
end

-- Outlines text drawn straight over the 3D view so it stays readable on fog and lamplight.
function Widgets.outline(label: TextLabel)
	Ui.textStroke(label, 2)
end

return Widgets
