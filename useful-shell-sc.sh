# Extact substring using grep
# ehco key="121"
grep -oP 'key="\K[^"]+'
