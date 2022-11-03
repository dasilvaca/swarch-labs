# Execute README.md instructions

# iterate over all the labs
for lab in $(ls -d */); do
    cd $lab
    echo "Running $lab"
    # chmod +x run.sh
    ./run.sh &
    cd ..
done