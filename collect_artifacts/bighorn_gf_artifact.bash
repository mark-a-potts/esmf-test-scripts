#!/bin/bash -l
rfile=$1


export homedir=/scratch/esmf/esmf_test/cronjobs/trunk/gfortran
export PATH=~/bin:$PATH

############################### Read the file for log directory and email recipient #######

datestamp=`date +%y%m`
logfile="${datestamp}_test"
echo " The logfile is $logfile"
here=`pwd`


if grep -i "LOG_DIR1" $rfile > tmp
then
        read location log_dir log_tmp < tmp
        cd $log_dir
        if test ! -d  $logfile
        then
                # Make new directory if doesn't exist
                mkdir $logfile
        fi
        cd $here
        echo "LOGDIR1 is $log_dir/$logfile"
        export LOGDIR=$log_dir/$logfile
fi

	echo "LOGDIR=$LOGDIR"

if grep -i "email_to" $rfile > tmp
then
        read location emailuser < tmp
        echo "Email user is $emailuser"
fi

if grep -i "email_title" $rfile > tmp
then
        read location email_title < tmp
        echo "Email title is $email_title"
fi


rm -f tmp

rm -f $LOGDIR/mailMessage
rm -f $LOGDIR/newMailMessage
rm -f $LOGDIR/header
rm -f $LOGDIR/mailHeader
rm -f $LOGDIR/newsummary
rm -f $LOGDIR/sum
rm -f $LOGDIR/summary

echo "" > $LOGDIR/header
echo "Script start time: `date`" >> $LOGDIR/header

# Set test status as green, assume it will run clean
echo "Test_results:green" > $LOGDIR/Test_Status

#Set day of the week
echo "Day_of_Week:`date +%A`" > $LOGDIR/Day_Started

#Set Number of test failure
echo "0" > $LOGDIR/Test_Failures

cd $homedir

chk_out_scripts

chmod a+x $homedir/bin/*

$homedir/bin/chk_out_esmf $rfile ESMF_Bighorn_gfortran

export PATH_org=$PATH
############################# Run the tests ###############################

 #source /glade/u/apps/ch/opt/lmod/7.5.3/lmod/lmod/init/bash
number=1
while grep "^$number " $rfile >tmp
do
	# Get the computer information
        read num location directory hostname abi site comp comm u_tests u_tests_type sys_test_type threaded mpmd ck_out_opt tag < tmp
        echo "$location $directory $hostname $abi $site $comp $comm $u_tests $u_tests_type $sys_test_type $threaded $mpmd $ck_out_opt $tag"
        cat tmp

	export ESMF_OS=`uname -s`
	export ESMF_DIR=$directory/esmf
	export ESMF_BENCHMARK_PREFIX=/scratch/esmf/esmf_test/cronjobs/trunk/gfortran/BENCHMARKDIR
	export LOGTMP=$log_tmp
	export OPT=g
	export ESMF_BOPT=g
	export SYS_TEST_TYPE=$sys_test_type
	export U_TESTS=$u_tests
	export U_TESTS_TYPE=$u_tests_type
	export ESMF_ABI=$abi
	export ESMF_SITE=$site
	export ESMF_COMPILER=$comp
	export ESMF_COMM=$comm
	export THREADED=$threaded
        export ESMF_INSTALL_PREFIX=/scratch/esmf/esmf_test/cronjobs/trunk/gfortran/install_dir
        export ESMF_TESTHARNESS_FIELD=RUN_ESMF_TestHarnessFieldUNI_1
        export ESMF_TESTHARNESS_ARRAY=RUN_ESMF_TestHarnessArrayUNI_2
	export ESMF_MPIRUN=mpirun

        rm -rf $ESMF_INSTALL_PREFIX/*
        if [[ $threaded = "THREADED" ]]
        then
                export ESMF_TESTWITHTHREADS=ON 
        else
                export ESMF_TESTWITHTHREADS=OFF
        fi 
        if [[ $u_tests = "EX" ]]
        then
                export ESMF_TESTEXHAUSTIVE=ON
        else 
                export ESMF_TESTEXHAUSTIVE=OFF
        fi 

        if [[ $mpmd = "MPMD" ]]
        then
                export ESMF_TESTMPMD=ON
        else
                export ESMF_TESTMPMD=OFF
        fi

	export MODULEPATH=$MODULEPATH":/project/esmf/modulefiles"
        
        if [[ $ESMF_COMPILER = "gfortran4" ]]
        then
            export ESMF_COMPILER=gfortran
            module purge
            module load compiler/gnu/4.8.5
            module load tool/hdf5/1.10.2/gcc-4.8.5 
            module load tool/netcdf/4.6.1/gcc-4.8.5
            module load mpich/3.2.1-gnu4.8.5
	    export ver=$(gfortran -dumpversion)
        fi
          
        if [[ $ESMF_COMPILER = "gfortran8" ]]
        then
            export ESMF_COMPILER=gfortran
	    module purge
            module load compiler/gnu/8.1.0   
            module load tool/hdf5/1.8.7/gcc      
            module load tool/netcdf/4.6.1/gcc-8.1.0
	    export ver=$(gfortran -dumpversion)
            
        fi
        
        if [[ $ESMF_COMM = "mp" ]]
        then
             export ESMF_COMM=mpich3   
             module load mpich/3.2.1-gnu8.1.0
        fi
	
	if [[ $ESMF_COMM = "mpic3" ]]
        then
             export ESMF_COMM=mpich3
             module load mpich/3.2.1-gnu4.8.5
        fi

	if [[ $ESMF_COMM = "openmpi" ]]
        then
                export ESMF_COMM=openmpi
	        module load openmpi/3.1.1-gnu8.1.0
        fi

	export my_make="gmake -j32"

        export RFile=$rfile
	echo "ESMF_DIR = $ESMF_DIR"
	cd $ESMF_DIR
        rm -rf $ESMF_INSTALL_PREFIX/*
	#$homedir/test_tutorial
	$homedir/bin/test_esmf_noq
	cd /home/himanshu/storage/develop
	x="${ESMF_OS}_${ESMF_COMPILER}_${ver}_${ESMF_COMM}"
	mkdir testg_$x
	mkdir examplesg_$x
	mkdir libg_$x
	mkdir appsg_$x
	mkdir g_outputfiles

	cp -rf $ESMF_DIR/test/testg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.Log testg_$x/
        cp -rf $ESMF_DIR/test/testg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*_results testg_$x/
	cp -rf $ESMF_DIR/test/testg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.config testg_$x/	
        cp -rf $ESMF_DIR/test/testg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.stdout testg_$x/
	cp -rf $ESMF_DIR/examples/examplesg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.Log examplesg_$x/
	cp -rf $ESMF_DIR/examples/examplesg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*_results examplesg_$x/
	cp -rf $ESMF_DIR/examples/examplesg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.config examplesg_$x/
cp -rf $ESMF_DIR/examples/examplesg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.stdout examplesg_$x/
	cp -rf $ESMF_DIR/lib/libg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/esmf.mk libg_$x/
	cp -rf $ESMF_DIR/apps/appsg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.Log appsg_$x/ 
	cp -rf $ESMF_DIR/apps/appsg/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.stdout appsg_$x/

	for f in *gfortran*.out; do mv "$f" "${f%.out}_g.out"; done
        mv *_g.out g_outputfiles/
	
	cd $homedir
	export OPT=O
	export ESMF_BOPT=O
	$homedir/bin/test_esmf_noq
	cd /home/himanshu/storage/develop
	mkdir testO_$x
        mkdir examplesO_$x
        mkdir libO_$ESMF_OS_$x
        mkdir appsO_$ESMF_OS_$x
	mkdir O_outputfiles

       cp -rf $ESMF_DIR/test/testO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.stdout testO_$x/
       cp -rf $ESMF_DIR/test/testO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*_results testO_$x/
       cp -rf $ESMF_DIR/test/testO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.config testO_$x/
       cp -rf $ESMF_DIR/examples/examplesO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.stdout examplesO_$x/
       cp -rf $ESMF_DIR/lib/libO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/esmf.mk libO_$x/
        cp -rf $ESMF_DIR/apps/appsO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.stdout appsO_$x/
	cp -rf $ESMF_DIR/test/testO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.Log testO_$x/
        cp -rf $ESMF_DIR/examples/examplesO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.Log examplesO_$x/
       cp -rf $ESMF_DIR/examples/examplesO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*_results examplesO_$x/
       cp -rf $ESMF_DIR/examples/examplesO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.config examplesO_$x/
	cp -rf $ESMF_DIR/apps/appsO/$ESMF_OS.$ESMF_COMPILER.64.$ESMF_COMM.default/*.Log appsO_$x/

	for h in *gfortran*.out; do mv "$h" "${h%.out}_O.out"; done
        mv *_O.out O_outputfiles/
	
	cd $homedir
        number=`expr $number + 1`
        echo "number = $number"
done
cd $homedir

cd /home/himanshu/storage/develop
rm meta_data_bighorn_gfortran.log
touch meta_data_bighorn_gfortran.log
cat /scratch/esmf/esmf_test/cronjobs/trunk/gfortran/esmf_logs/*/Test_Status >> meta_data_bighorn_gfortran.log
echo "Test_Failures :" `cat /scratch/esmf/esmf_test/cronjobs/trunk/gfortran/esmf_logs/*/Test_Failures` >> meta_data_bighorn_gfortran.log
echo "Test_artifacts made at" `date` >> meta_data_bighorn_gfortran.log

#cd /scratch/esmf/esmf_test/cronjobs/trunk/gfortran/esmf_logs/2011_test/
#cp -rf ESMFdailyLog /home/himanshu/storage/develop/ESMF_Trunk_Bighorn_gfortran.html
#sed -i '1i<pre>' /home/himanshu/storage/develop/ESMF_Trunk_Bighorn_gfortran.html

cd ~/storage/esmf-test-artifacts/
git pull


cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/g/mpich3/3.2.1/apps/
touch a.sh
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/appsg_Linux_gfortran_8.1.0_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/4.8.5/g/mpich3/3.2.1/apps/
touch b.sh
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/appsg_Linux_gfortran_4.8.5_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm b.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/g/openmpi/3.1.1/apps/
touch c.sh
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/appsg_Linux_gfortran_8.1.0_openmpi/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm c.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/4.8.5/O/mpich3/3.2.1/apps/
touch d.sh
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/appsO_Linux_gfortran_4.8.5_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm d.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/O/mpich3/3.2.1/apps/
touch e.sh
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/appsO_Linux_gfortran_8.1.0_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm e.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/O/openmpi/3.1.1/apps/
touch f.sh
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/appsO_Linux_gfortran_8.1.0_openmpi/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm f.sh



cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/g/mpich3/3.2.1/lib/
touch a.sh
git rm *.mk
cp -rf ~/storage/develop/libg_Linux_gfortran_8.1.0_mpich3/* .
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/4.8.5/g/mpich3/3.2.1/lib/
touch a.sh
git rm *.mk
cp -rf ~/storage/develop/libg_Linux_gfortran_4.8.5_mpich3/* .
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/g/openmpi/3.1.1/lib/
touch a.sh
git rm *.mk
cp -rf ~/storage/develop/libg_Linux_gfortran_8.1.0_openmpi/* .
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/4.8.5/O/mpich3/3.2.1/lib/
touch a.sh
git rm *.mk
cp -rf ~/storage/develop/libO_Linux_gfortran_4.8.5_mpich3/* .
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/O/mpich3/3.2.1/lib/
touch a.sh
git rm *.mk
cp -rf ~/storage/develop/libO_Linux_gfortran_8.1.0_mpich3/* .
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/O/openmpi/3.1.1/lib/
touch a.sh
git rm *.mk
cp -rf ~/storage/develop/libO_Linux_gfortran_8.1.0_openmpi/* .
rm a.sh


cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/g/mpich3/3.2.1/examples
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/examplesg_Linux_gfortran_8.1.0_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/4.8.5/g/mpich3/3.2.1/examples
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/examplesg_Linux_gfortran_4.8.5_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/g/openmpi/3.1.1/examples
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/examplesg_Linux_gfortran_8.1.0_openmpi/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/4.8.5/O/mpich3/3.2.1/examples
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/examplesO_Linux_gfortran_4.8.5_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/O/mpich3/3.2.1/examples
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/examplesO_Linux_gfortran_8.1.0_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/O/openmpi/3.1.1/examples
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/examplesO_Linux_gfortran_8.1.0_openmpi/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/g/mpich3/3.2.1/test
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/testg_Linux_gfortran_8.1.0_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/4.8.5/g/mpich3/3.2.1/test
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/testg_Linux_gfortran_4.8.5_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/g/openmpi/3.1.1/test
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/testg_Linux_gfortran_8.1.0_openmpi/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/4.8.5/O/mpich3/3.2.1/test
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/testO_Linux_gfortran_4.8.5_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/O/mpich3/3.2.1/test
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/testO_Linux_gfortran_8.1.0_mpich3/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/O/openmpi/3.1.1/test
touch a.sh
git rm *.config
git rm *_results
git rm *.stdout
git rm *.Log
cp -rf ~/storage/develop/testO_Linux_gfortran_8.1.0_openmpi/* .
for h in *.Log; do date >> $h; done
for i in *.stdout; do date >> $i; done
rm a.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/4.8.5/g/mpich3/3.2.1/out/
touch e.sh
git rm *.out
cp -rf ~/storage/develop/g_outputfiles/build_apps_*4.8.5mpich3_g.out build_apps.out
cp -rf ~/storage/develop/g_outputfiles/build_examples_*4.8.5mpich3_g.out build_examples.out
cp -rf ~/storage/develop/g_outputfiles/build_Linux*4.8.5mpich3_g.out build.out
cp -rf ~/storage/develop/g_outputfiles/build_quick_start_*4.8.5mpich3_g.out build_quick_start.out
cp -rf ~/storage/develop/g_outputfiles/build_system_tests_*4.8.5mpich3_g.out build_system_tests.out
cp -rf ~/storage/develop/g_outputfiles/build_unit_tests_*4.8.5mpich3_g.out build_unit_tests.out
cp -rf ~/storage/develop/g_outputfiles/installcheck_*4.8.5mpich3_g.out installcheck.out
cp -rf ~/storage/develop/g_outputfiles/install_Linux*4.8.5mpich3_g.out install.out
cp -rf ~/storage/develop/g_outputfiles/run_examples_*4.8.5mpich3_g.out run_examples.out
cp -rf ~/storage/develop/g_outputfiles/run_system_tests_*4.8.5mpich3_g.out run_system_tests.out
cp -rf ~/storage/develop/g_outputfiles/run_unit_tests_Linux*4.8.5mpich3_g.out run_unit_tests.out
cp -rf ~/storage/develop/g_outputfiles/install_unit_tests_benchmark_*4.8.5mpich3_g.out install_unit_tests_benchmark.out
cp -rf ~/storage/develop/g_outputfiles/run_examples_uni_*4.8.5mpich3_g.out run_examples_uni.out
cp -rf ~/storage/develop/g_outputfiles/run_system_tests_uni_*4.8.5mpich3_g.out run_system_tests_uni.out
cp -rf ~/storage/develop/g_outputfiles/run_unit_tests_uni_*4.8.5mpich3_g.out run_unit_tests_uni.out
cp -rf ~/storage/develop/g_outputfiles/run_unit_tests_benchmark_*4.8.5mpich3_g.out  run_unit_tests_benchmark.out
for h in *.out; do date >> $h; done
rm e.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/g/mpich3/3.2.1/out/
touch e.sh
git rm *.out
cp -rf ~/storage/develop/g_outputfiles/build_apps_*8.1.0mpich3_g.out build_apps.out
cp -rf ~/storage/develop/g_outputfiles/build_examples_*8.1.0mpich3_g.out build_examples.out
cp -rf ~/storage/develop/g_outputfiles/build_Linux*8.1.0mpich3_g.out build.out
cp -rf ~/storage/develop/g_outputfiles/build_quick_start_*8.1.0mpich3_g.out build_quick_start.out
cp -rf ~/storage/develop/g_outputfiles/build_system_tests_*8.1.0mpich3_g.out build_system_tests.out
cp -rf ~/storage/develop/g_outputfiles/build_unit_tests_*8.1.0mpich3_g.out build_unit_tests.out
cp -rf ~/storage/develop/g_outputfiles/installcheck_*8.1.0mpich3_g.out installcheck.out
cp -rf ~/storage/develop/g_outputfiles/install_Linux*8.1.0mpich3_g.out install.out
cp -rf ~/storage/develop/g_outputfiles/run_examples_*8.1.0mpich3_g.out run_examples.out
cp -rf ~/storage/develop/g_outputfiles/run_system_tests_*8.1.0mpich3_g.out run_system_tests.out
cp -rf ~/storage/develop/g_outputfiles/run_unit_tests_Linux*8.1.0mpich3_g.out run_unit_tests.out
cp -rf ~/storage/develop/g_outputfiles/install_unit_tests_benchmark_*8.1.0mpich3_g.out install_unit_tests_benchmark.out
cp -rf ~/storage/develop/g_outputfiles/run_examples_uni_*8.1.0mpich3_g.out run_examples_uni.out
cp -rf ~/storage/develop/g_outputfiles/run_system_tests_uni_*8.1.0mpich3_g.out run_system_tests_uni.out
cp -rf ~/storage/develop/g_outputfiles/run_unit_tests_uni_*8.1.0mpich3_g.out run_unit_tests_uni.out
cp -rf ~/storage/develop/g_outputfiles/run_unit_tests_benchmark_*8.1.0mpich3_g.out  run_unit_tests_benchmark.out
for h in *.out; do date >> $h; done
rm e.sh


cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/g/openmpi/3.1.1/out/
touch d.sh
git rm *.out
cp -rf ~/storage/develop/g_outputfiles/build_apps_*8.1.0openmpi_g.out build_apps.out
cp -rf ~/storage/develop/g_outputfiles/build_examples_*8.1.0openmpi_g.out build_examples.out
cp -rf ~/storage/develop/g_outputfiles/build_Linux*8.1.0openmpi_g.out build.out
cp -rf ~/storage/develop/g_outputfiles/build_quick_start_*8.1.0openmpi_g.out build_quick_start.out
cp -rf ~/storage/develop/g_outputfiles/build_system_tests_*8.1.0openmpi_g.out build_system_tests.out
cp -rf ~/storage/develop/g_outputfiles/build_unit_tests_*8.1.0openmpi_g.out build_unit_tests.out
cp -rf ~/storage/develop/g_outputfiles/installcheck_*8.1.0openmpi_g.out installcheck.out
cp -rf ~/storage/develop/g_outputfiles/install_Linux*8.1.0openmpi_g.out install.out
cp -rf ~/storage/develop/g_outputfiles/run_examples_*8.1.0openmpi_g.out run_examples.out
cp -rf ~/storage/develop/g_outputfiles/run_system_tests_*8.1.0openmpi_g.out run_system_tests.out
cp -rf ~/storage/develop/g_outputfiles/run_unit_tests_Linux*8.1.0openmpi_g.out run_unit_tests.out
cp -rf ~/storage/develop/g_outputfiles/install_unit_tests_benchmark_*8.1.0openmpi_g.out install_unit_tests_benchmark.out
cp -rf ~/storage/develop/g_outputfiles/run_examples_uni_*8.1.0openmpi_g.out run_examples_uni.out
cp -rf ~/storage/develop/g_outputfiles/run_system_tests_uni_*8.1.0openmpi_g.out run_system_tests_uni.out
cp -rf ~/storage/develop/g_outputfiles/run_unit_tests_uni_*8.1.0openmpi_g.out run_unit_tests_uni.out
cp -rf ~/storage/develop/g_outputfiles/run_unit_tests_benchmark_*8.1.0openmpi_g.out  run_unit_tests_benchmark.out
for h in *.out; do date >> $h; done
rm d.sh

cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/4.8.5/O/mpich3/3.2.1/out/
touch c.sh
git rm *.out
cp -rf ~/storage/develop/O_outputfiles/build_apps_*4.8.5mpich3_O.out build_apps.out
cp -rf ~/storage/develop/O_outputfiles/build_examples_*4.8.5mpich3_O.out build_examples.out
cp -rf ~/storage/develop/O_outputfiles/build_Linux*4.8.5mpich3_O.out build.out
cp -rf ~/storage/develop/O_outputfiles/build_quick_start_*4.8.5mpich3_O.out build_quick_start.out
cp -rf ~/storage/develop/O_outputfiles/build_system_tests_*4.8.5mpich3_O.out build_system_tests.out
cp -rf ~/storage/develop/O_outputfiles/build_unit_tests_*4.8.5mpich3_O.out build_unit_tests.out
cp -rf ~/storage/develop/O_outputfiles/installcheck_*4.8.5mpich3_O.out installcheck.out
cp -rf ~/storage/develop/O_outputfiles/install_Linux*4.8.5mpich3_O.out install.out
cp -rf ~/storage/develop/O_outputfiles/run_examples_*4.8.5mpich3_O.out run_examples.out
cp -rf ~/storage/develop/O_outputfiles/run_system_tests_*4.8.5mpich3_O.out run_system_tests.out
cp -rf ~/storage/develop/O_outputfiles/run_unit_tests_Linux*4.8.5mpich3_O.out run_unit_tests.out
cp -rf ~/storage/develop/O_outputfiles/install_unit_tests_benchmark_*4.8.5mpich3_O.out install_unit_tests_benchmark.out
cp -rf ~/storage/develop/O_outputfiles/run_examples_uni_*4.8.5mpich3_O.out run_examples_uni.out
cp -rf ~/storage/develop/O_outputfiles/run_system_tests_uni_*4.8.5mpich3_O.out run_system_tests_uni.out
cp -rf ~/storage/develop/O_outputfiles/run_unit_tests_uni_*4.8.5mpich3_O.out run_unit_tests_uni.out
cp -rf ~/storage/develop/O_outputfiles/run_unit_tests_benchmark_*4.8.5mpich3_O.out  run_unit_tests_benchmark.out
for h in *.out; do date >> $h; done
rm c.sh


cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/O/mpich3/3.2.1/out/
touch b.sh
git rm *.out
cp -rf ~/storage/develop/O_outputfiles/build_apps_*8.1.0mpich3_O.out build_apps.out
cp -rf ~/storage/develop/O_outputfiles/build_examples_*8.1.0mpich3_O.out build_examples.out
cp -rf ~/storage/develop/O_outputfiles/build_Linux*8.1.0mpich3_O.out build.out
cp -rf ~/storage/develop/O_outputfiles/build_quick_start_*8.1.0mpich3_O.out build_quick_start.out
cp -rf ~/storage/develop/O_outputfiles/build_system_tests_*8.1.0mpich3_O.out build_system_tests.out
cp -rf ~/storage/develop/O_outputfiles/build_unit_tests_*8.1.0mpich3_O.out build_unit_tests.out
cp -rf ~/storage/develop/O_outputfiles/installcheck_*8.1.0mpich3_O.out installcheck.out
cp -rf ~/storage/develop/O_outputfiles/install_Linux*8.1.0mpich3_O.out install.out
cp -rf ~/storage/develop/O_outputfiles/run_examples_*8.1.0mpich3_O.out run_examples.out
cp -rf ~/storage/develop/O_outputfiles/run_system_tests_*8.1.0mpich3_O.out run_system_tests.out
cp -rf ~/storage/develop/O_outputfiles/run_unit_tests_Linux*8.1.0mpich3_O.out run_unit_tests.out
cp -rf ~/storage/develop/O_outputfiles/install_unit_tests_benchmark_*8.1.0mpich3_O.out install_unit_tests_benchmark.out
cp -rf ~/storage/develop/O_outputfiles/run_examples_uni_*8.1.0mpich3_O.out run_examples_uni.out
cp -rf ~/storage/develop/O_outputfiles/run_system_tests_uni_*8.1.0mpich3_O.out run_system_tests_uni.out
cp -rf ~/storage/develop/O_outputfiles/run_unit_tests_uni_*8.1.0mpich3_O.out run_unit_tests_uni.out
cp -rf ~/storage/develop/O_outputfiles/run_unit_tests_benchmark_*8.1.0mpich3_O.out  run_unit_tests_benchmark.out
for h in *.out; do date >> $h; done
rm b.sh


cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/8.1.0/O/openmpi/3.1.1/out/
touch a.sh
git rm *.out
cp -rf ~/storage/develop/O_outputfiles/build_apps_*8.1.0openmpi_O.out build_apps.out
cp -rf ~/storage/develop/O_outputfiles/build_examples_*8.1.0openmpi_O.out build_examples.out
cp -rf ~/storage/develop/O_outputfiles/build_Linux*8.1.0openmpi_O.out build.out
cp -rf ~/storage/develop/O_outputfiles/build_quick_start_*8.1.0openmpi_O.out build_quick_start.out
cp -rf ~/storage/develop/O_outputfiles/build_system_tests_*8.1.0openmpi_O.out build_system_tests.out
cp -rf ~/storage/develop/O_outputfiles/build_unit_tests_*8.1.0openmpi_O.out build_unit_tests.out
cp -rf ~/storage/develop/O_outputfiles/installcheck_*8.1.0openmpi_O.out installcheck.out
cp -rf ~/storage/develop/O_outputfiles/install_Linux*8.1.0openmpi_O.out install.out
cp -rf ~/storage/develop/O_outputfiles/run_examples_*8.1.0openmpi_O.out run_examples.out
cp -rf ~/storage/develop/O_outputfiles/run_system_tests_*8.1.0openmpi_O.out run_system_tests.out
cp -rf ~/storage/develop/O_outputfiles/run_unit_tests_Linux*8.1.0openmpi_O.out run_unit_tests.out
cp -rf ~/storage/develop/O_outputfiles/install_unit_tests_benchmark_*8.1.0openmpi_O.out install_unit_tests_benchmark.out
cp -rf ~/storage/develop/O_outputfiles/run_examples_uni_*8.1.0openmpi_O.out run_examples_uni.out
cp -rf ~/storage/develop/O_outputfiles/run_system_tests_uni_*8.1.0openmpi_O.out run_system_tests_uni.out
cp -rf ~/storage/develop/O_outputfiles/run_unit_tests_uni_*8.1.0openmpi_O.out run_unit_tests_uni.out
cp -rf ~/storage/develop/O_outputfiles/run_unit_tests_benchmark_*8.1.0openmpi_O.out  run_unit_tests_benchmark.out
for h in *.out; do date >> $h; done
rm a.sh


cd ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/
touch a.sh
git rm summary.log
#git rm *.html 
cp -rf ~/storage/develop/meta_data_bighorn_gfortran.log summary.log
#cp -rf ~/storage/develop/ESMF_Trunk_Bighorn_gfortran.html result.html
rm a.sh

cd /home/himanshu/storage/esmf-test-artifacts
#git log --since=6.days --grep='Bighorn GFortran artifacts' > ~/storage/esmf-test-artifacts/develop/bighorn/gfortran/commit.log

git add .
git commit -m " Bighorn GFortran artifacts pushed at `date`"
git push origin master



cd $homedir

echo "end of test script"
exit

