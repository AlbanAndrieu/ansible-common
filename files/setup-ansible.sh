#/bin/bash
# {{ ansible_managed }}

function check_linux_distro() {
	distro=$1; shift
	grep $distro /etc/issue &> /dev/null; echo $?
}

sudo_cmd=
os_type="$(uname -o)"
test "$os_type" == "" && os_type="$(uname)"
echo "Found os type $os_type"
if [ "$os_type" == "Cygwin" ]; then
	test -f /bin/git
    if [ "$?" == "1" ]; then
    	echo "Please install git from cygwin" && exit 1
	fi

	echo "Installing apt-cyg"
	tmp_dir=$(mktemp -d) || exit 1
	git clone https://github.com/grlee/apt-cyg $tmp_dir || exit 1
	cp -f $tmp_dir/apt-cyg /bin  || exit 1
	chmod +x /bin/apt-cyg  || exit 1
	rm -rf $tmp_dir

	echo "Installing cygwin packages for ansible dependencies"
	apt-cyg install python gcc-core wget openssh 
	if [ "$?" == "1" ]; then
		echo "Check that mirror site is correct."
		echo "Use apt-cyg -m <url> show to set a new mirror"
		exit 1
	fi

	echo "Installing setuptools"
	wget --no-check-certificate https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O - | python

	echo "Installing pip"
	easy_install pip
elif [ "$os_type" == "GNU/Linux" ]; then
	echo "Found Linux distro"
	if [ "$(check_linux_distro Ubuntu)" == "0" ]; then
		sudo_cmd=sudo
		echo "Found Ubuntu distro"
		echo "Installing pip"
		sudo apt-get install python-dev python-pip -y || exit 1
	elif [ "$(check_linux_distro CentOS)" == "0" ]; then
		sudo_cmd=sudo
		echo "Found CentOS distro"
		sudo rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
		sudo yum install ansible -y || exit 1		
	elif [ "$(check_linux_distro Red)" == "0" ]; then
		sudo_cmd=sudo
		echo "Found Red Hat distro"
		#TODO find a ansible role that manage python 27 for red hat too
		echo "Make sure python 27 is installed"
		echo "https://www.digitalocean.com/community/tutorials/how-to-set-up-python-2-7-6-and-3-3-3-on-centos-6-4"

        wget http://www.python.org/ftp/python/2.7.6/Python-2.7.6.tar.xz

		# Let's decode (-d) the XZ encoded tar archive:
		xz -d Python-2.7.6.tar.xz

		# Now we can perform the extraction:
		tar -xvf Python-2.7.6.tar

		# Let's download the installation file using wget:
		#wget --no-check-certificate https://pypi.python.org/packages/source/s/setuptools/setuptools-1.4.2.tar.gz

		# Extract the files from the archive:
		#tar -xvf setuptools-1.4.2.tar.gz

		# Enter the extracted directory:
		#cd setuptools-1.4.2

		# Install setuptools using the Python we've installed (2.7.6)
		#python2.7 setup.py install

		echo "Installing pip"
        curl https://raw.githubusercontent.com/pypa/pip/master/contrib/get-pip.py | python2.7 -

        #pip install virtualenv

		echo "Switch env to python 27"
        export PATH="/opt/rh/python27/root/usr/bin:/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
        export LD_LIBRARY_PATH="/opt/rh/python27/root/usr/lib64"

        python -V
        python2.7 -V

        pip -V

		sudo pip2.7 install ansible || exit 1		
	else
		echo "Unknown Linux distro: $(cat /etc/issue)" && exit 1
	fi
elif [ "$os_type" == "Darwin" ]; then
#	echo -n "Installing home brew... "
#	ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)" &> /dev/null && echo "OK" || {echo "FAILED"; exit 1 }

#	echo -n "Test if home brew is installed... "
#	brew --version &> /dev/null && echo "OK"
#    if [ "$?" == "1"]; then
#		echo "FAILED" && exit 1
#	fi

	echo "Installing pip"
	pip --version &> /dev/null || sudo easy_install pip || exit 1
else
	echo "Not a supported platform" && exit 1
fi

echo "Sudo command is '$sudo_cmd'"

echo -n "Test if pip is installed..."
pip --version &> /dev/null && echo "OK" 
if [ "$?" == "1" ]; then 
	echo "FAILED"; exit 1
fi

echo -n "Installing passlib..."
$sudo_cmd pip install passlib --upgrade && echo "OK"
if [ "$?" == "1" ]; then
	echo "FAILED"; exit 1
fi

echo -n "Installing ansible..."
$sudo_cmd pip install ansible --upgrade && echo "OK"
if [ "$?" == "1" ]; then
	echo "FAILED"; exit 1
fi

echo -n "Test ansible is installed... "
ansible --version &> /dev/null && echo "OK"
if [ "$?" == "1" ]; then
    echo "FAILED"; exit 1
fi

exit 0
