# potion_colors.gd
extends Object
class_name PotionColors

enum PotionColor {
	GREEN,
	RED,
	BLUE,
	YELLOW,
	PURPLE,
	CYAN,
	ORANGE,
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
		PotionColor.PURPLE:
			return Color.MEDIUM_PURPLE
		PotionColor.CYAN:
			return Color.DEEP_SKY_BLUE
		PotionColor.ORANGE:
			return Color.DARK_ORANGE
		PotionColor.EMPTY:
			return Color.TRANSPARENT
		_:
			return Color.AQUAMARINE
