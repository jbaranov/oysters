#!/bin/sh
# chkconfig: 345 99 55
# description: script to start unicorn
# /etc/init.d/[application]_unicorn

# source functions library
. /etc/rc.d/init.d/functions

# source application params
. /etc/sysconfig/deployed_application

start() {
  local program
  local options
  local env_vars

  cd $ROOT_PATH

  echo "Starting Unicorn"
  env_vars="RAILS_ENV=$RAILS_ENV BUNDLE_GEMFILE=$BUNDLE_GEMFILE"
  options="-c $UNICORN_CONFIG -E $RAILS_ENV -D "
  program="source /home/$APP_USER/.bash_profile; $env_vars bundle exec unicorn $options"

  if [[ $APP_USER == $USER ]]
  then
    daemon --pidfile=$UNICORN_PIDFILE $program
  else
    daemon --user $APP_USER --pidfile=$UNICORN_PIDFILE $program
  fi
  RETVAL=$?

  if [ $RETVAL -eq 0 ]; then
    echo_success
  else
    echo_failure
  fi
  echo
}

stop() {
  echo "Stopping Unicorn"

  if [ -f $UNICORN_PIDFILE ]; then
    kill -s QUIT $(cat $UNICORN_PIDFILE)
    RETVAL=$?
  else
    RETVAL=1
  fi

  if [ $RETVAL -eq 0 ]; then
    rm -f $UNICORN_PIDFILE
  else
    echo "Unicorn is not running"
  fi
  echo_success
}

case "$1" in
  start) start ;;
  stop) stop ;;
  restart)
    echo "Restarting Unicorn ... "
    stop
    sleep 5
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit $?
