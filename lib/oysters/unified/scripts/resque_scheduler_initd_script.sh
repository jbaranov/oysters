#!/bin/sh
# chkconfig: 345 99 55
# description: script to start resque scheduler
# /etc/init.d/[application]_resque_scheduler

# source functions library
. /etc/rc.d/init.d/functions

# source application params
. /etc/sysconfig/deployed_application

start() {
  local program
  local options

  cd $ROOT_PATH

  echo "Starting Resque Scheduler"
  options="RAILS_ENV=$RAILS_ENV VERBOSE=$SCHEDULER_VERBOSE BACKGROUND=$BACKGROUND DYNAMIC_SCHEDULE=$DYNAMIC_SCHEDULE PIDFILE=$SCHEDULER_PIDFILE"
  program="source /home/$APP_USER/.bash_profile; bundle exec rake resque:scheduler $options 2>&1 >> $SCHEDULER_LOGFILE"

  if [[ $APP_USER == $USER ]]
  then
    daemon --pidfile=$SCHEDULER_PIDFILE $program
  else
    daemon --user $APP_USER --pidfile=$SCHEDULER_PIDFILE $program
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
  echo "Stopping Resque Scheduler"

  if [ -f $SCHEDULER_PIDFILE ]; then
    kill -s QUIT $(cat $SCHEDULER_PIDFILE)
    RETVAL=$?
  else
    RETVAL=1
  fi

  if [ $RETVAL -eq 0 ]; then
    rm -f $SCHEDULER_PIDFILE
  else
    echo "Resque Scheduler is not running"
  fi
  echo_success
}

case "$1" in
  start) start ;;
  stop) stop ;;
  restart)
    echo "Restarting Resque scheduler ... "
    stop
    sleep 2
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit $?
