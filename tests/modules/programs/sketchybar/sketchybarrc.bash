export COLOR=0xff0000ff
export FONT=SF Pro
export PADDING=3

sketchybar --bar \
height=30 \
padding_left=10 \
padding_right=10 \
position=top

sketchybar --default \
background.height=24 \
icon.color=$COLOR \
icon.font=$FONT


sketchybar --add item clock right --set clock script=./scripts/clock.sh update_freq=1


# This is a test configuration
sketchybar --add item cpu right \
          --set cpu script="$PLUGIN_DIR/cpu.sh" \
          --subscribe cpu system_woke


sketchybar --update