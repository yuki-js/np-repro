while true; do

# if `python3 imp-ext.py` takes more than 10 seconds, kill it
timeout -s 9 4 python3 imp-ext.py

done