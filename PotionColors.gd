# potion_colors.gd
extends Object
class_name PotionColors

enum PotionColor {
	GREEN,
	RED,
	BLUE,
	YELLOW,
	EMPTY
}

static func get_color(potion_color: PotionColors.PotionColor) -> Color:
	match potion_color:
		PotionColor.GREEN:
			return Color.WEB_GREEN
		PotionColor.RED:
			return Color.MEDIUM_VIOLET_RED
		PotionColor.BLUE:
			return Color.DARK_BLUE
		PotionColor.YELLOW:
			return Color.GREEN_YELLOW
		PotionColor.EMPTY:
			return Color.TRANSPARENT
		_:
			return Color.AQUAMARINE
