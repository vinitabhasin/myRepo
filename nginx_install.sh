#!/bin/bash

###### Start of function usage ########
### It displays the help and usage of the script ######
usage()
{
    cat << EOT
    nginx_install.sh installs nginx and configures it to serve on port 8000.

    usage: nginx_install.sh [-h|--help] <command>
    Available commands are:
        install         Installs nginx and web-site
        uninstall       Uninstalls nginx
EOT
}
######  End of function ########


###### Start of function required_cmds ########
### It checks for required cmds, if they are not installed,######
### ask user to install them. ######
required_cmds ()
{
  for cmd in "curl" "git" "yum"
  do
    which_cmd=$(which $cmd)
    if [[ ! -x $which_cmd ]]; then
        echo "nginx_install.sh requires $cmd. Please install and retry."
        return 1
    fi
  done
}
######  End of function ########


###### Start of function nginx install ########
### installs nginx and web-site to a directory
nginx_install()
{
  install_dir=/tmp/nginx_dir
  if [[ ! -d $install_dir ]]; then
     mkdir -p $install_dir; cd $install_dir
  else
     rm -fr $install_dir
  fi

  main_log=$(readlink -f ./nginx_main.log)
  touch $main_log
  echo "nginx_install.sh started at $(date)" > $main_log
  install_log=$(readlink -f ./install.log)
  touch $install_log

  which_cmd=$(which nginx)
  if [[ -x $which_cmd ]]; then
     echo "nginx is already installed. Doing nothing."
     echo "nginx is already installed. Doing nothing." >> $main_log
     exit
  fi

  # installing nginx using yum
  yum install nginx -y > $install_log 2>&1
  if [[ $? -ne 0 ]]; then
    echo "yum installation has failed. Please check $install_log."
    exit
  fi
  echo "Installed nginx"
  echo "Installed nginx" >> $main_log

  # download website source
  website_src="https://github.com/puppetlabs/exercise-webpage"
  git clone $website_src >> $install_log 2>&1
  if [[ $? -ne 0 ]]; then
    echo "git cloning has failed. Please check $install_log"
    exit
  fi
  echo "Cloned web site from $website_src" >> $main_log

  # update nginx config
  sed -i 's/listen       80/listen       8000/' /etc/nginx/nginx.conf >> $install_log 2>&1
  if [[ $? -ne 0 ]]; then
    echo "unable to update nginx conf. Please check $install_log"
    exit
  fi
  echo "Updated nginx config to listen on port 8000"
  echo "Updated nginx config to listen on port 8000" >> $main_log

  # copy web-site files to serve
  mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.orig
  rsync -a --exclude=".*" exercise-webpage/ /usr/share/nginx/html/ >> $install_log 2>&1
  if [[ $? -ne 0 ]]; then
    echo "failed to update code. Please check $install_log"
    exit
  fi
  echo "Updated code to nginx area" >> $main_log


  # start nginx service
  service nginx start >> $install_log 2>&1
  if [[ $? -ne 0 ]]; then
    echo "failed to start nginx service. Please check $install_log"
    exit
  fi
  echo "Started nginx on port 8000."
  echo "Started nginx on port 8000."  >> $main_log

  #test
  curl -s -X GET http://localhost:8000 > ./test.index.html
  different=$(diff --brief ./test.index.html ./exercise-webpage/index.html)
  if [ -n "$different" ]; then
    echo "Test GET of index.html failed. Please check $install_log"
  else
    echo "Test GET of index.html OK" >> $main_log
  fi
  echo "nginx-install.sh done at $(date)" >> $main_log

}
######  End of function ########

###### Start of function nginx uninstall ########
### unstalls nginx
nginx_uninstall ()
{
  install_dir=/tmp/nginx_dir
  if [[ -d $install_dir ]]; then
     cd $install_dir
  else
     mkdir -p $install_dir
     cd $install_dir
  fi

  main_log=$(readlink -f ./nginx_uninstall.log)
  touch $main_log

  #removing the installation
  which_cmd=$(which nginx)
  if [[ -x $which_cmd ]]; then
     yum erase nginx -y > $main_log 2>&1
     if [[ $? -ne 0 ]]; then
        echo "uninstallation has failed. Please check $main_log."
        exit
     fi
     echo "Uninstalled nginx"
  fi
  rm -fr $install_dir

}
######  End of function ########



# main script
required_cmds || exit 1

options=$@
for arg in $options
do
  case $arg in
  -h|--help) usage
               exit;;
  install)
         nginx_install ;;
  uninstall)
         nginx_uninstall ;;
  esac
done

