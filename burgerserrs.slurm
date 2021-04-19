#!/bin/bash
#SBATCH -J eg1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=18
#SBATCH --gres=gpu:3
#SBATCH -t 12:00:00
#SBATCH -A PSYC0002
#SBATCH -p qTRDGPUH


cd `pwd`
export MKL_NUM_THREADS=6
DATANAME="burgers"
CONSTRAINT=(2 frozen)
kernel_size=5
stablize=0
SPARSITY=(0.005 0)
SCHEME=(upwind central)
momentsparsity=0.001
viscosity=0.05
noise=0.001
data_start_time=1
DEVICES=4
REPEATSIZE=20
i=0

source /home/users/mabavisani/anaconda3/bin/activate
conda activate PDE-Net-2

for constraint in ${CONSTRAINT[@]}; do
    for scheme in ${SCHEME[@]}; do
        for sparsity in ${SPARSITY[@]}; do
            # for ((trainidx=0;trainidx<24;trainidx++)) do
                name=${DATANAME}-${constraint}-${scheme}-sparse${sparsity}-noise${noise}
                for ((i=0;i<$REPEATSIZE;i++))
                do
                    DEVICENUM=`expr $i % $DEVICES`
                    echo "repeat batch:$i, select device:$DEVICENUM"
                    python _test.py $name $i cuda:$DEVICENUM &
                    echo $name $i cuda:$DEVICENUM
                    sleep 0.1
                    if [ "$DEVICENUM" -eq `expr $DEVICES - 1` ]
                    then
                        echo 'wait'
                        wait
                    fi
                done
                wait
                echo 'aggregate errs'
                python test.py $name $REPEATSIZE
            # done
        done
    done
done
wait
