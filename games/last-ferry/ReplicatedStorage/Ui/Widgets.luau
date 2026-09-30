--!strict
-- Pieces the HUD and the overlay cards share: captions, wrapped paragraphs, and
-- rule rows (new rules bold with a NEW tag).

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

function Widgets.ruleRow(parent: Instance, index: number, rule: View.RuleLine, textSize: number)
	local row = Ui.frame(parent, "Rule", UDim2.fromScale(1, 0))
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.LayoutOrder = 10 + index
	Ui.label(row, "Number", {
		text = tostring(index),
		font = F.title,
		size = textSize + 1,
		color = C.lamp,
		frameSize = UDim2.fromOffset(20, textSize + 4),
	})
	Ui.label(row, "Text", {
		text = rule.text,
		font = if rule.isNew then F.bodyBold else F.body,
		size = textSize,
		color = if rule.isNew then C.text else C.muted,
		wrap = true,
		frameSize = UDim2.new(1, if rule.isNew then -66 else -24, 0, 0),
		position = UDim2.fromOffset(24, 0),
		autoSize = Enum.AutomaticSize.Y,
		lineHeight = 1.05,
	})
	if rule.isNew then
		local tag = Ui.label(row, "New", {
			text = "NEW",
			font = F.title,
			size = 13,
			color = C.ink,
			xAlign = Enum.TextXAlignment.Center,
			frameSize = UDim2.fromOffset(38, 18),
			position = UDim2.new(1, 0, 0, 1),
			anchor = Vector2.new(1, 0),
		})
		tag.BackgroundTransparency = 0
		tag.BackgroundColor3 = C.lamp
		Ui.corner(tag, UDim.new(0, 4))
	end
end

-- Outlines text drawn straight over the 3D view so it stays readable on fog and lamplight.
function Widgets.outline(label: TextLabel)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Color = C.ink
	stroke.Thickness = 1.5
	stroke.Transparency = 0.35
	stroke.Parent = label
end

return Widgets
