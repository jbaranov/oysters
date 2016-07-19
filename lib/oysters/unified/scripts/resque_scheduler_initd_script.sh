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

  options="RAILS_ENV=$RAILS_ENV VERBOSE=$SCHEDULER_VERBOSE BACKGROUND=$BACKGROUND DYNAMIC_SCHEDULE=$DYNAMIC_SCHEDULE PIDFILE=$SCHEDULER_PIDFILE"
  program="source /home/$APP_USER/.bash_profile; bundle exec rake resque:scheduler $options 2>&1 >> $SCHEDULER_LOGFILE"

  action 'Starting Resque Scheduler...' daemon --user "${APP_USER#$USER}" --pidfile=$SCHEDULER_PIDFILE $program

  # workaround to allow Resque Scheduler to setup a trap for HUP signal
  sleep 5
}

stop() {
  if [ -f $SCHEDULER_PIDFILE ]; then
    action 'Stopping Resque Scheduler...' _stop_with_wait $(cat $SCHEDULER_PIDFILE)
  else
    echo 'Resque Scheduler is not running'
  fi
}

_stop_with_wait() {
  local pid delay tries try

  delay=2
  tries=3
  pid=$1
  try=0

  kill -s QUIT $pid

  while [ $try -lt $tries ] ; do
    checkpid $pid || return 0
    sleep $delay
    let try+=1
  done
}

case "$1" in
  start) start ;;
  stop) stop ;;
  restart)
    echo "Restarting Resque scheduler ... "
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit $?
